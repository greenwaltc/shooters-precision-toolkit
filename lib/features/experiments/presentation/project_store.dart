import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/foundation/behavior_policy.dart';
import '../../../shared/foundation/diagnostics.dart';
import '../../../shared/foundation/json_object.dart';
import '../../../shared/ui/product_configuration.dart';
import '../api/project_draft_storage.dart';
import '../api/project_repository.dart';
import 'saved_project.dart';
import 'test_design/project_form_model.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// The status displayed for edits to a project.
enum ProjectSaveState { saved, dirty, saving, conflict, error }

/// The loading and availability states for the workspace's project list.
enum WorkspaceLoadState { loading, empty, ready, error }

/// A point-in-time view of one editable project's persistence state.
/// The project is the live editing model; the metadata is captured by value.
@immutable
class ProjectEditState {
  /// Captures the edit and save status of a project while retaining its
  /// editable model.
  const ProjectEditState({
    required this.project,
    required this.revision,
    required this.editCounter,
    required this.isDirty,
    required this.isSaving,
    required this.error,
    this.draftError,
  });

  final SavedProject project;
  final int revision;
  final int editCounter;
  final bool isDirty;
  final bool isSaving;
  final Object? error;
  final Object? draftError;

  /// Whether the cloud version conflicts with this local edit.
  bool get hasConflict => error is ProjectConflict;

  /// The state to show for this edit, taking any pending save or error into
  /// account.
  ProjectSaveState get saveState {
    if (isSaving) {
      return ProjectSaveState.saving;
    }
    if (hasConflict) {
      return ProjectSaveState.conflict;
    }
    if (error != null) {
      return ProjectSaveState.error;
    }
    return isDirty ? ProjectSaveState.dirty : ProjectSaveState.saved;
  }
}

/// Owns subscriptions, debounce timers, and editable projects for one account.
/// Disposing invalidates listener generations immediately. Already-started I/O
/// may finish, but must not notify or update a disposed workspace.
class ProjectStore extends ChangeNotifier with WidgetsBindingObserver {
  /// Creates a workspace store and attaches a Flutter lifecycle observer.
  ///
  /// Call [load] to start reading projects and dispose the store when the
  /// workspace ends. [saveDebounce] delays automatic saves and
  /// [initialLoadTimeout] limits the wait for the first result.
  ProjectStore({
    required this.repository,
    required this.draftStorage,
    this.saveDebounce = BehaviorPolicy.saveDebounce,
    this.initialLoadTimeout = BehaviorPolicy.initialCloudLoadTimeout,
    required this.clock,
    this.diagnostics = const NoopDiagnostics(),
    this.featureFlags = FeatureFlags.defaults,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Clock clock;
  final Diagnostics diagnostics;
  final FeatureFlags featureFlags;
  final ProjectRepository repository;
  final ProjectDraftStorage draftStorage;
  final Duration saveDebounce;
  final Duration initialLoadTimeout;
  Timer? _initialLoadDeadline;
  bool _recentFromCache = true;
  bool? _selectedFromCache;

  /// Whether the recent-project list has a current server result and no load
  /// error.
  bool get hasCurrentCloudData => !_recentFromCache && _loadError == null;

  /// Checks whether the workspace can treat its data for [id] as current.
  ///
  /// For the selected project, an explicit cache result from its own listener
  /// also makes it stale.
  bool isProjectCurrent(String id) =>
      hasCurrentCloudData &&
      (id != _selectedProjectId || _selectedFromCache != true);
  final _projects = <String, SavedProject>{};
  final _projectListeners = <String, VoidCallback>{};
  final _revisions = <String, int>{};
  final _editVersions = <String, int>{};
  final _observedContents = <String, String>{};
  final _dirty = <String>{};
  final _saving = <String>{};
  final _deleting = <String>{};
  final _saveErrors = <String, Object>{};
  final _draftErrors = <String, Object>{};
  final _restoredDrafts = <String>{};
  final _pendingRemote = <String, CloudProject>{};
  final _remoteDeletions = <String>{};
  // Page records are separate from the editable models/drafts in _projects.
  // The latter also retains viewed records that leave the bounded live query.
  List<CloudProject> _recentPage = [];
  final _olderPages = <List<CloudProject>>[];
  CloudProject? _olderCursor;
  String? _pageOrdering;
  int _paginationGeneration = 0;
  bool _isLoadingOlder = false;
  bool _hasMoreProjects = false;
  Object? _olderProjectsError;
  UnmodifiableListView<SavedProject>? _sortedProjects;
  StreamSubscription<ProjectPage>? _projectsSubscription;
  StreamSubscription<CloudProject?>? _selectedSubscription;
  Future<void> _operationTail = Future.value();
  Future<void> _draftOperationTail = Future.value();
  Future<void>? _loadFuture;
  Completer<void>? _initialLoad;
  final _saveDebounceTimers = <String, Timer>{};
  String? _selectedProjectId;
  Object? _loadError;
  int _loadGeneration = 0;
  int _selectionGeneration = 0;
  bool _isLoaded = false;
  bool _draftsLoaded = false;
  bool _disposed = false;

  /// Whether an initial project list has been received.
  bool get isLoaded => _isLoaded;

  /// Whether a request for an older page is in progress.
  bool get isLoadingOlder => _isLoadingOlder;

  /// Whether another page of older projects may be available.
  bool get hasMoreProjects => _hasMoreProjects;

  /// The last error while loading older projects, or null when no such error is
  /// recorded.
  Object? get olderProjectsError => _olderProjectsError;

  /// The current workspace loading error, or null when no error is recorded.
  Object? get loadError => _loadError;

  /// The state to display for the project list, including an empty workspace.
  WorkspaceLoadState get loadState {
    if (_loadError != null) {
      return WorkspaceLoadState.error;
    }
    if (!_isLoaded) {
      return WorkspaceLoadState.loading;
    }
    return _projects.isEmpty
        ? WorkspaceLoadState.empty
        : WorkspaceLoadState.ready;
  }

  /// Whether any project still has edits awaiting a save.
  bool get hasUnsavedChanges => _dirty.isNotEmpty;

  /// The editable project currently selected, or null when nothing is selected.
  SavedProject? get selectedProject => _projects[_selectedProjectId];

  /// The known cloud revision for [id], or zero when no revision is recorded.
  int revisionFor(String id) => _revisions[id] ?? 0;

  /// The current draft or save error for [id], or null when neither is
  /// recorded. Draft errors take priority.
  Object? saveErrorFor(String id) => _draftErrors[id] ?? _saveErrors[id];

  /// Captures the current edit state for [id], or returns null when the project
  /// is unknown.
  ProjectEditState? editStateFor(String id) {
    final project = _projects[id];
    if (project == null) {
      return null;
    }
    return ProjectEditState(
      project: project,
      revision: revisionFor(id),
      editCounter: _editVersions[id] ?? 0,
      isDirty: _dirty.contains(id),
      isSaving: _saving.contains(id),
      error: saveErrorFor(id),
      draftError: _draftErrors[id],
    );
  }

  /// The display status for [id]. Unknown projects default to saved.
  ProjectSaveState saveStateFor(String id) =>
      editStateFor(id)?.saveState ?? ProjectSaveState.saved;

  /// Checks whether a conflict can be discarded in favor of a newer server
  /// version or confirmed deletion.
  ///
  /// Returns false during a save or deletion.
  bool canDiscardDraft(String id) =>
      !_saving.contains(id) &&
      !_deleting.contains(id) &&
      (_remoteDeletions.contains(id) ||
          (_pendingRemote[id]?.isFromCache == false &&
              (_pendingRemote[id]?.revision ?? 0) > revisionFor(id)));

  /// Saves a conflicted draft as a new project and selects the copy.
  ///
  /// Throws [StateError] if the workspace is unavailable or the project has no
  /// conflict ready to resolve. If saving the copy fails, it remains in the
  /// workspace as a draft the user can retry. Later edits to the original are
  /// preserved.
  Future<SavedProject> saveConflictAsNewProject(String id) async {
    _requireLoaded();
    final original = _projects[id];
    if (original == null ||
        _saveErrors[id] is! ProjectConflict ||
        _saving.contains(id)) {
      throw StateError('This project has no conflict to resolve.');
    }
    _captureChanges(original);
    final originalCounter = _editVersions[id];
    final copy = _newProjectCopy(original);
    _projects[copy.id] = copy;
    _revisions[copy.id] = 0;
    _attachProjectListener(copy);
    _markChanged(copy);
    _select(copy.id);
    _notifyIfActive();
    // On failure the copy remains a recoverable draft with an explicit Retry.
    await _queueSave(copy.id);
    if (!_disposed &&
        _editVersions[id] == originalCounter &&
        canDiscardDraft(id)) {
      discardConflictingDraft(id);
    }
    return copy;
  }

  /// Replaces a conflicting draft with the current server version or removes
  /// it if the server confirmed its deletion.
  ///
  /// Call this after user confirmation. Throws [StateError] if the draft
  /// cannot be discarded yet.
  void discardConflictingDraft(String id) {
    if (_disposed || !canDiscardDraft(id)) {
      throw StateError('An acknowledged cloud version is not available yet.');
    }
    final remote = _pendingRemote.remove(id);
    _saveDebounceTimers.remove(id)?.cancel();
    // _draftOperationTail observes and exposes failures through draftError.
    unawaited(_queueDraftChange(id, () => draftStorage.remove(id)));
    _dirty.remove(id);
    _saveErrors.remove(id);
    if (_remoteDeletions.remove(id)) {
      _removeProject(id, selectNext: false);
    } else {
      final existing = _projects[id];
      if (existing != null) {
        _observedContents[id] = _contents(existing);
      }
      _acceptRemote(remote!);
    }
    _notifyIfActive();
  }

  /// The projects currently known to the workspace in newest-first order.
  ///
  /// The list is read-only, but its projects remain editable.
  List<SavedProject> get projects => _sortedProjects ??= UnmodifiableListView(
    _projects.values.toList()..sort((a, b) {
      final byDate = b.updatedAt.compareTo(a.updatedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    }),
  );

  /// Attaches once and completes when the first result or loading error arrives.
  /// A subsequent call after an error retries without discarding existing data.
  Future<void> load() {
    if (_disposed) {
      return Future.error(StateError('Workspace is disposed.'));
    }
    if (_loadFuture != null && _loadError == null) {
      return _loadFuture!;
    }
    final generation = ++_loadGeneration;
    final first = Completer<void>();
    _initialLoad = first;
    _loadFuture = first.future;
    _loadError = null;
    _initialLoadDeadline?.cancel();
    _initialLoadDeadline = Timer(
      initialLoadTimeout,
      () => _handleProjectLoadError(
        const AppFailure(FailureKind.unavailable),
        generation,
      ),
    );
    _notifyIfActive();
    // _subscribe translates failures to loadState and completes the initial
    // load. Generation checks reject results after replacement or disposal.
    unawaited(_subscribe(generation));
    return first.future;
  }

  bool _isCurrentLoad(int generation) =>
      !_disposed && generation == _loadGeneration;

  void _completeInitialLoad() {
    final first = _initialLoad;
    if (first != null && !first.isCompleted) {
      first.complete();
    }
  }

  /// Restores drafts once and attaches the recent-project listener.
  ///
  /// Each attempt has its own [generation]. Work that finishes after a retry
  /// or disposal must leave the current workspace alone.
  Future<void> _subscribe(int generation) async {
    try {
      await _projectsSubscription?.cancel();
      if (!_isCurrentLoad(generation)) {
        return;
      }
      if (!_draftsLoaded) {
        final drafts = await draftStorage.readAll();
        if (!_isCurrentLoad(generation)) {
          return;
        }
        for (final entry in drafts.entries) {
          final project = SavedProject.fromJson(entry.value.project.toJson());
          project.formModel.featureFlags = featureFlags;
          _projects[entry.key] = project;
          _revisions[entry.key] = entry.value.expectedRevision;
          _editVersions[entry.key] = entry.value.editCounter;
          _observedContents[entry.key] = _contents(project);
          _dirty.add(entry.key);
          _restoredDrafts.add(entry.key);
          _attachProjectListener(project);
        }
        _sortedProjects = null;
        _draftsLoaded = true;
      }
      _projectsSubscription = repository.watchProjects().listen(
        (page) => _applyRecentPage(page, generation),
        onError: (Object error, StackTrace stack) {
          _handleProjectLoadError(error, generation, stack);
        },
        onDone: () {
          // A dead subscription must not leave load() permanently returning its
          // old completed future. Keep the original error if one preceded done.
          if (_isCurrentLoad(generation) && _loadError == null) {
            _handleProjectLoadError(
              StateError('The project subscription ended. Please retry.'),
              generation,
            );
          }
        },
      );
    } catch (error, stack) {
      _handleProjectLoadError(error, generation, stack);
    }
  }

  void _applyRecentPage(ProjectPage page, int generation) {
    if (!_isCurrentLoad(generation)) {
      return;
    }
    try {
      _recentFromCache = page.isFromCache;
      if (!page.isFromCache) {
        _initialLoadDeadline?.cancel();
      }
      if (!_isLoaded && page.isFromCache && page.isEmpty) {
        _notifyIfActive();
        return;
      }
      final firstPage = !_isLoaded;
      final ordering = jsonEncode([
        for (final record in page)
          [
            record.project.id,
            record.project.updatedAt.toIso8601String(),
            record.hasPendingWrites,
          ],
      ]);
      _recentPage = List.unmodifiable(page);
      if (ordering != _pageOrdering) {
        _pageOrdering = ordering;
        _resetPagination();
      }
      for (final record in page) {
        // _acceptRemote buffers updates while dirty/saving, and only replaces a
        // clean model after detaching its previous form listener.
        _acceptRemote(record);
      }
      // A bounded query losing a document does not establish its deletion.
      _isLoaded = true;
      _loadError = null;
      if (firstPage && _selectedProjectId == null && _projects.isNotEmpty) {
        _select(projects.first.id);
      }
      for (final id in _restoredDrafts.toList()) {
        _scheduleSave(id);
        _restoredDrafts.remove(id);
      }
      _completeInitialLoad();
      _notifyIfActive();
    } catch (error, stack) {
      _handleProjectLoadError(error, generation, stack);
    }
  }

  void _resetPagination() {
    _paginationGeneration++;
    // Old models remain visible, but their old cursors are no longer current.
    _olderPages.clear();
    final acknowledged = _recentPage.where(
      (record) => !record.hasPendingWrites,
    );
    _olderCursor = acknowledged.isEmpty ? null : acknowledged.last;
    _hasMoreProjects = _recentPage.length == ProjectRepository.pageSize;
    _olderProjectsError = null;
  }

  /// Requests the next page of older projects if loading can proceed.
  ///
  /// A failure is stored in [olderProjectsError] so the existing list remains
  /// usable.
  Future<void> loadOlderProjects() async {
    final cursor = _olderCursor;
    if (_disposed ||
        !_isLoaded ||
        _loadError != null ||
        _isLoadingOlder ||
        !_hasMoreProjects ||
        cursor == null) {
      return;
    }
    final generation = _paginationGeneration;
    _isLoadingOlder = true;
    _olderProjectsError = null;
    _notifyIfActive();
    try {
      final page = await repository.fetchOlderProjects(after: cursor);
      if (_disposed || generation != _paginationGeneration) {
        return;
      }
      for (final record in page) {
        _acceptRemote(record);
      }
      _olderPages.add(List.unmodifiable(page));
      if (page.isNotEmpty) {
        _olderCursor = page.last;
      }
      _hasMoreProjects = page.length == ProjectRepository.pageSize;
    } catch (error) {
      if (!_disposed && generation == _paginationGeneration) {
        _olderProjectsError = error;
      }
    } finally {
      _isLoadingOlder = false;
      _notifyIfActive();
    }
  }

  void _handleProjectLoadError(
    Object error,
    int generation, [
    StackTrace? stack,
  ]) {
    if (!_isCurrentLoad(generation)) {
      return;
    }
    diagnostics.record(
      DiagnosticEvent.workspaceLoadFailed,
      error: error,
      stack: stack,
    );
    // Retain projects, selection, dirty drafts and revisions for retry.
    _initialLoadDeadline?.cancel();
    _loadError = error;
    _completeInitialLoad();
    _notifyIfActive();
  }

  /// Creates and selects a new project, then attempts its first cloud save.
  ///
  /// The workspace must be loaded before creating a project. If the cloud
  /// save fails, the future reports the error and the new draft stays selected.
  Future<SavedProject> createProject() async {
    _requireLoaded();
    final now = clock.now().toUtc();
    final project = SavedProject(
      id: repository.newProjectId(),
      createdAt: now,
      updatedAt: now,
      formModel: ProjectFormModel(featureFlags: featureFlags),
    );
    _projects[project.id] = project;
    _revisions[project.id] = 0;
    _attachProjectListener(project);
    _markChanged(project);
    _select(project.id);
    _notifyIfActive();
    await _queueSave(project.id);
    return project;
  }

  /// Saves an independent copy of the current design and matrix for [id].
  ///
  /// The copy receives a fresh ID and a title derived from [title], shortened
  /// if needed to fit storage. The selected project does not change. The
  /// future returns the saved copy or reports a write error. No local draft
  /// is added on failure.
  /// Throws [StateError] if the workspace or source project is unavailable.
  Future<SavedProject> cloneProject(String id, {required String title}) async {
    _requireLoaded();
    final original = _projects[id];
    if (original == null || _deleting.contains(id)) {
      throw StateError('This project is no longer available to clone.');
    }
    final copy = _newProjectCopy(original);
    final limit = BehaviorPolicy.maxProjectTitleLength;
    final characters = title.runes.take(limit + 1).toList();
    copy.formModel.setProjectTitle(
      characters.length <= limit
          ? title
          : '${String.fromCharCodes(characters.take(limit - 1))}…',
    );
    return _saveNewCopy(copy);
  }

  /// Saves a validated portable [snapshot] as a separate workspace project.
  ///
  /// Keeps the file's title and data, assigns a new identity and timestamps,
  /// and leaves selection unchanged. Throws [FormatException] if the file
  /// claims a complete design with missing or invalid design fields. The
  /// workspace must be loaded and the write must succeed before the copy is
  /// added to the list.
  Future<SavedProject> importProject(ProjectSnapshot snapshot) async {
    _requireLoaded();
    final copy = _newProjectCopy(snapshot);
    if (copy.setupComplete && !copy.formModel.isSetupValid) {
      throw const FormatException('The imported design is incomplete.');
    }
    return _saveNewCopy(copy);
  }

  Future<SavedProject> _saveNewCopy(SavedProject copy) async {
    await _enqueue(() async {
      if (_disposed) {
        throw StateError('Workspace is disposed.');
      }
      try {
        final revision = await repository.saveProject(
          copy,
          expectedRevision: 0,
        );
        // The list subscription can deliver the server copy before the write
        // returns. In that case it already has the authoritative timestamps.
        if (!_disposed && revisionFor(copy.id) < revision) {
          _acceptRemote(CloudProject(copy, revision, false));
          _notifyIfActive();
        }
      } catch (error, stack) {
        diagnostics.record(
          DiagnosticEvent.workspaceSaveFailed,
          error: error,
          stack: stack,
        );
        rethrow;
      }
    });
    return _projects[copy.id] ?? copy;
  }

  /// Copies persisted fields into a new editable model with its own identity.
  SavedProject _newProjectCopy(ProjectDocument original) {
    final now = clock.now().toUtc().toIso8601String();
    final json = decodeJsonObject(jsonEncode(original.toJson()))
      ..['id'] = repository.newProjectId()
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    final copy = SavedProject.fromJson(json);
    copy.formModel.featureFlags = featureFlags;
    return copy;
  }

  /// Selects a known project and listens for updates to it.
  ///
  /// An unknown ID or an already selected project leaves the selection
  /// unchanged.
  Future<void> selectProject(String projectId) async {
    if (_disposed || !_projects.containsKey(projectId)) {
      return;
    }
    if (_selectedProjectId == projectId) {
      return;
    }
    _select(projectId);
    _notifyIfActive();
  }

  /// Records direct matrix/map edits without waiting for an explicit save call.
  void markProjectChanged(String id) {
    final project = _projects[id];
    if (_disposed || project == null || !_captureChanges(project)) {
      return;
    }
    project.touch(clock.now());
    _notifyIfActive();
  }

  void _select(String? id) {
    _selectedProjectId = id;
    _selectedFromCache = null;
    final generation = ++_selectionGeneration;
    unawaited(_observeCancellation(_selectedSubscription?.cancel()));
    _selectedSubscription = null;
    // A new draft does not exist on the server yet. An initial missing
    // snapshot could arrive after creation and look like a deletion.
    if (id == null || _disposed || revisionFor(id) == 0) {
      return;
    }
    _selectedSubscription = repository
        .watchProject(id)
        .listen(
          (record) {
            if (_disposed || generation != _selectionGeneration) {
              return;
            }
            if (_deleting.contains(id)) {
              return;
            }
            if (record != null) {
              _selectedFromCache = record.isFromCache;
              final previous = _projects[id];
              if (!record.hasPendingWrites &&
                  previous != null &&
                  previous.updatedAt != record.project.updatedAt &&
                  !_recentPage.any(
                    (item) =>
                        item.project.id == id &&
                        item.project.updatedAt == record.project.updatedAt,
                  )) {
                _resetPagination();
              }
              _acceptRemote(record);
            } else if (revisionFor(id) > 0) {
              if (_dirty.contains(id) || _saving.contains(id)) {
                _remoteDeletions.add(id);
                if (!_saving.contains(id)) {
                  _saveErrors[id] = ProjectConflict(id);
                }
              } else {
                _removeProject(id, selectNext: false);
              }
            }
            _notifyIfActive();
          },
          onError: (Object error, StackTrace stack) {
            if (_disposed || generation != _selectionGeneration) {
              return;
            }
            _loadError = error;
            _notifyIfActive();
          },
        );
  }

  /// Applies a cloud record when it is safe to replace the local model.
  ///
  /// If a local edit or save is pending, holds the incoming version for
  /// reconciliation so a remote update cannot overwrite work in progress.
  void _acceptRemote(CloudProject record) {
    final id = record.project.id;
    if (_deleting.contains(id) || record.hasPendingWrites) {
      return;
    }
    final existing = _projects[id];
    if (existing != null) {
      _captureChanges(existing);
    }
    if (_dirty.contains(id) || _saving.contains(id)) {
      final pending = _pendingRemote[id];
      if (pending == null || record.revision >= pending.revision) {
        _pendingRemote[id] = record;
      }
      if (!_saving.contains(id) && record.revision > revisionFor(id)) {
        _saveErrors[id] = ProjectConflict(id);
        _saveDebounceTimers.remove(id)?.cancel();
      }
      return;
    }
    if (record.revision < revisionFor(id)) {
      return;
    }
    if (existing != null && _contents(existing) == _contents(record.project)) {
      existing.updatedAt = record.project.updatedAt;
    } else {
      _detachProjectListener(id);
      final remoteProject = SavedProject.fromJson(record.project.toJson());
      remoteProject.formModel.featureFlags = featureFlags;
      _projects[id] = remoteProject;
      _attachProjectListener(remoteProject);
    }
    _revisions[id] = record.revision;
    _observedContents[id] = _contents(_projects[id]!);
    _sortedProjects = null;
  }

  /// Requests deletion of [projectId] using its known revision.
  ///
  /// Returns true if the deleted project was selected. An unknown project or
  /// one already being deleted returns false. A write failure is recorded and
  /// rethrown.
  Future<bool> deleteProject(String projectId) async {
    _requireLoaded();
    if (!_projects.containsKey(projectId) || _deleting.contains(projectId)) {
      return false;
    }
    _deleting.add(projectId);
    var deletedSelection = false;
    try {
      await _enqueue(() async {
        if (_disposed) {
          throw StateError('Workspace is disposed.');
        }
        await repository.deleteProject(
          projectId,
          expectedRevision: revisionFor(projectId),
        );
        await _queueDraftChange(
          projectId,
          () => draftStorage.remove(projectId),
        );
        if (_disposed) {
          return;
        }
        deletedSelection = _selectedProjectId == projectId;
        _removeProject(projectId);
      });
      return deletedSelection;
    } catch (error) {
      _saveErrors[projectId] = error;
      rethrow;
    } finally {
      _deleting.remove(projectId);
      _notifyIfActive();
    }
  }

  /// Records edits locally and debounces cloud upload, including matrix changes.
  Future<void> persistSelectedProject({bool markModified = false}) async {
    if (_disposed) {
      return;
    }
    final project = selectedProject;
    if (project == null) {
      return;
    }
    _syncSetupComplete(project);
    if (markModified) {
      project.touch(clock.now());
    }
    _captureChanges(project);
    _notifyIfActive();
    await _draftOperationTail;
    if (_draftErrors[project.id] case final error?) {
      throw error;
    }
  }

  /// An explicit Save/Retry action bypasses debounce for the selected project.
  Future<void> saveSelectedProject() async {
    final id = selectedProject?.id;
    if (_disposed || id == null) {
      return;
    }
    if (!_dirty.contains(id) && _draftErrors.containsKey(id)) {
      await _queueDraftChange(id, () => draftStorage.remove(id));
      _saveErrors.remove(id);
      _notifyIfActive();
      return;
    }
    await _queueSave(id);
  }

  /// Marks the selected project's design complete and waits for the session
  /// draft update.
  ///
  /// Returns false if no project is selected or its design is invalid.
  /// Completion does not wait for cloud acknowledgement.
  Future<bool> completeProjectSetup() async {
    final project = selectedProject;
    if (project == null || !project.formModel.isSetupValid) {
      return false;
    }
    if (!project.setupComplete) {
      project.setupComplete = true;
      project.touch(clock.now());
      _captureChanges(project);
    }
    await _draftOperationTail;
    if (_draftErrors[project.id] case final error?) {
      throw error;
    }
    _notifyIfActive();
    return true;
  }

  /// A successful flush means every currently dirty project was acknowledged.
  Future<void> flush() async {
    _requireLoaded();
    for (final timer in _saveDebounceTimers.values) {
      timer.cancel();
    }
    _saveDebounceTimers.clear();
    for (final project in _projects.values) {
      _captureChanges(project);
    }
    // Include changes made while a previous save was in flight.
    do {
      await _operationTail;
      for (final id in _dirty.toList()) {
        await _queueSave(id);
      }
    } while (_dirty.isNotEmpty && !_disposed);
    await _draftOperationTail;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operationTail.then((_) => operation());
    // Keep the queue usable after failures; the caller still receives the error.
    _operationTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  Future<void> _queueSave(String id, {bool automatic = false}) =>
      _enqueue(() => _saveProject(id, automatic: automatic));

  /// Saves a frozen revision and only clears the edits that revision contains.
  ///
  /// If an edit arrives while the request is pending, its draft is kept and
  /// rebased on the acknowledged revision. Automatic saves leave errors for
  /// the user to resolve rather than retrying a failed operation repeatedly.
  Future<void> _saveProject(String id, {bool automatic = false}) async {
    if (_disposed || _deleting.contains(id)) {
      return;
    }
    if (automatic && saveErrorFor(id) != null) {
      return;
    }
    final project = _projects[id];
    if (project == null) {
      return;
    }
    _captureChanges(project);
    if (!_dirty.contains(id)) {
      return;
    }
    _saveDebounceTimers.remove(id)?.cancel();
    final version = _editVersions[id];
    final expectedRevision = revisionFor(id);
    final snapshot = SavedProject.fromJson(
      decodeJsonObject(jsonEncode(project.toJson())),
    );
    final acknowledgedDraft = ProjectDraft.capture(
      snapshot,
      expectedRevision,
      version!,
    );
    _saving.add(id);
    _saveErrors.remove(id);
    _notifyIfActive();
    try {
      // Local writes and cleanup share an ordered queue. An old acknowledgement
      // cannot remove a newer draft, and failed local writes stop cloud upload.
      await _writeDraft(id);
      if (_disposed) {
        return;
      }
      final revision = await repository.saveProject(
        snapshot,
        expectedRevision: expectedRevision,
      );
      if (_disposed) {
        return;
      }
      _revisions[id] = revision;
      if (expectedRevision == 0 && _selectedProjectId == id) {
        _select(id);
      }
      _captureChanges(project);
      if (_editVersions[id] == version) {
        _dirty.remove(id);
        await _queueDraftChange(id, () async {
          await draftStorage.removeIfMatches(id, acknowledgedDraft);
        });
      } else {
        // Rebase only on our own acknowledged write; retain all later edits.
        await _writeDraft(id);
      }
      _saving.remove(id);
      final remote = _pendingRemote.remove(id);
      if (_remoteDeletions.remove(id)) {
        if (_dirty.contains(id)) {
          _saveErrors[id] = ProjectConflict(id);
        } else {
          _removeProject(id, selectNext: false);
        }
      } else if (remote != null && !_dirty.contains(id)) {
        _acceptRemote(remote);
      } else if (remote != null && remote.revision > revisionFor(id)) {
        _pendingRemote[id] = remote;
      }
      if (_dirty.contains(id) && !_saveErrors.containsKey(id)) {
        // A successful older snapshot must never mark newer edits as saved.
        // This also catches map mutations that have no form-model listener.
        _scheduleSave(id);
      }
    } catch (error, stack) {
      diagnostics.record(
        DiagnosticEvent.workspaceSaveFailed,
        error: error,
        stack: stack,
      );
      if (!_disposed) {
        _saveErrors[id] = error;
      }
      rethrow;
    } finally {
      _saving.remove(id);
      _notifyIfActive();
    }
  }

  // Only domain content is compared: server updatedAt acknowledgement is not an edit.
  String _contents(ProjectDocument project) => jsonEncode(
    _canonical(
      Map<String, Object?>.from(project.toJson())..remove('updatedAt'),
    ),
  );

  Object? _canonical(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List<Object?>) {
      return value.map(_canonical).toList();
    }
    return value;
  }

  bool _captureChanges(SavedProject project) {
    if (_observedContents[project.id] != _contents(project)) {
      _markChanged(project);
      return true;
    }
    return false;
  }

  void _markChanged(SavedProject project) {
    _observedContents[project.id] = _contents(project);
    _editVersions[project.id] = (_editVersions[project.id] ?? 0) + 1;
    _dirty.add(project.id);
    _sortedProjects = null;
    // The ordered draft tail handles errors even for these detached writes.
    unawaited(_writeDraft(project.id));
    _scheduleSave(project.id);
  }

  void _attachProjectListener(SavedProject project) {
    _detachProjectListener(project.id);
    void listener() {
      if (_disposed) {
        return;
      }
      project.touch(clock.now());
      _syncSetupComplete(project);
      _captureChanges(project);
      _notifyIfActive();
    }

    _projectListeners[project.id] = listener;
    project.formModel.addListener(listener);
  }

  void _detachProjectListener(String id) {
    final listener = _projectListeners.remove(id);
    if (listener != null) {
      _projects[id]?.formModel.removeListener(listener);
    }
  }

  void _removeProject(String id, {bool selectNext = true}) {
    _recentPage = _recentPage
        .where((record) => record.project.id != id)
        .toList();
    _pageOrdering = null;
    _resetPagination(); // Reject any fetch started before confirmed deletion.
    _detachProjectListener(id);
    _projects.remove(id);
    _revisions.remove(id);
    _editVersions.remove(id);
    _observedContents.remove(id);
    _dirty.remove(id);
    _saveErrors.remove(id);
    _draftErrors.remove(id);
    _restoredDrafts.remove(id);
    _saveDebounceTimers.remove(id)?.cancel();
    _pendingRemote.remove(id);
    _remoteDeletions.remove(id);
    _sortedProjects = null;
    if (_selectedProjectId == id) {
      _select(selectNext && _projects.isNotEmpty ? projects.first.id : null);
    }
  }

  void _syncSetupComplete(SavedProject project) {
    if (project.setupComplete && !project.formModel.isSetupValid) {
      project.setupComplete = false;
    }
  }

  Future<void> _queueDraftChange(String id, Future<void> Function() change) {
    final next = _draftOperationTail.then((_) => change());
    _draftOperationTail = next.then<void>(
      (_) {
        if (_draftErrors.remove(id) != null) {
          _notifyIfActive();
        }
      },
      onError: (Object error, StackTrace _) {
        _draftErrors[id] = error;
        _saveDebounceTimers.remove(id)?.cancel();
        _notifyIfActive();
      },
    );
    return next;
  }

  Future<void> _writeDraft(String id) {
    final project = _projects[id];
    if (project == null) {
      return Future.value();
    }
    final draft = ProjectDraft.capture(
      project,
      revisionFor(id),
      _editVersions[id]!,
    );
    return _queueDraftChange(id, () => draftStorage.write(id, draft));
  }

  void _scheduleSave(String id) {
    if (_disposed || saveErrorFor(id) != null) {
      return;
    }
    _saveDebounceTimers.remove(id)?.cancel();
    _saveDebounceTimers[id] = Timer(saveDebounce, () {
      _saveDebounceTimers.remove(id);
      unawaited(
        _queueSave(id, automatic: true).catchError((Object _, StackTrace _) {
          // Failed projects remain paused until an explicit Save/Retry.
        }),
      );
    });
  }

  void _saveInBackground() {
    if (_disposed || !_isLoaded) {
      return;
    }
    for (final project in _projects.values) {
      _captureChanges(project);
      if (_dirty.contains(project.id)) {
        _scheduleSave(project.id);
      }
    }
  }

  void _requireLoaded() {
    if (_disposed) {
      throw StateError('Workspace is disposed.');
    }
    if (!_isLoaded) {
      throw StateError('The workspace is still loading.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveInBackground();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _initialLoadDeadline?.cancel();
    _loadGeneration++;
    _selectionGeneration++;
    for (final timer in _saveDebounceTimers.values) {
      timer.cancel();
    }
    _saveDebounceTimers.clear();
    unawaited(_observeCancellation(_projectsSubscription?.cancel()));
    unawaited(_observeCancellation(_selectedSubscription?.cancel()));
    if (_initialLoad != null && !_initialLoad!.isCompleted) {
      _initialLoad!.complete();
    }
    for (final id in _projectListeners.keys.toList()) {
      _detachProjectListener(id);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _notifyIfActive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Cancellation is detached from synchronous dispose/selection callbacks;
  /// failures are reported without reviving the disposed notifier.
  static Future<void> _observeCancellation(Future<void>? cancellation) async {
    try {
      await cancellation;
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'project store',
          context: ErrorDescription('while cancelling a project subscription'),
        ),
      );
    }
  }
}
