// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../storage/project_repository.dart';
import 'project_form_model.dart';
import 'saved_project.dart';

enum ProjectSaveState { saved, dirty, saving, conflict, error }

enum WorkspaceLoadState { loading, empty, ready, error }

/// A point-in-time view of one editable project's persistence state.
/// The project is the live editing model; the metadata is captured by value.
@immutable
class ProjectEditState {
  const ProjectEditState({
    required this.project,
    required this.revision,
    required this.editCounter,
    required this.isDirty,
    required this.isSaving,
    required this.error,
  });

  final SavedProject project;
  final int revision;
  final int editCounter;
  final bool isDirty;
  final bool isSaving;
  final Object? error;
  bool get hasConflict => error is ProjectConflict;

  ProjectSaveState get saveState {
    if (isSaving) return ProjectSaveState.saving;
    if (hasConflict) return ProjectSaveState.conflict;
    if (error != null) return ProjectSaveState.error;
    return isDirty ? ProjectSaveState.dirty : ProjectSaveState.saved;
  }
}

/// Owns editable projects for one account, independently of the persistence SDK.
class ProjectStore extends ChangeNotifier with WidgetsBindingObserver {
  ProjectStore({
    required this.repository,
    this.saveDebounce = const Duration(seconds: 2),
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final ProjectRepository repository;
  final Duration saveDebounce;
  final _projects = <String, SavedProject>{};
  final _projectListeners = <String, VoidCallback>{};
  final _revisions = <String, int>{};
  final _editVersions = <String, int>{};
  final _observedContents = <String, String>{};
  final _dirty = <String>{};
  final _saving = <String>{};
  final _deleting = <String>{};
  final _saveErrors = <String, Object>{};
  final _pendingRemote = <String, CloudProject>{};
  final _remoteDeletions = <String>{};
  UnmodifiableListView<SavedProject>? _sortedProjects;
  StreamSubscription<List<CloudProject>>? _projectsSubscription;
  StreamSubscription<CloudProject?>? _selectedSubscription;
  Future<void> _operationTail = Future.value();
  Future<void>? _loadFuture;
  Completer<void>? _initialLoad;
  Timer? _saveDebounceTimer;
  String? _selectedProjectId;
  Object? _loadError;
  int _loadGeneration = 0;
  int _selectionGeneration = 0;
  bool _isLoaded = false;
  bool _disposed = false;

  bool get isLoaded => _isLoaded;
  Object? get loadError => _loadError;
  WorkspaceLoadState get loadState {
    if (_loadError != null) return WorkspaceLoadState.error;
    if (!_isLoaded) return WorkspaceLoadState.loading;
    return _projects.isEmpty
        ? WorkspaceLoadState.empty
        : WorkspaceLoadState.ready;
  }

  bool get hasUnsavedChanges => _dirty.isNotEmpty;
  SavedProject? get selectedProject => _projects[_selectedProjectId];
  int revisionFor(String id) => _revisions[id] ?? 0;
  Object? saveErrorFor(String id) => _saveErrors[id];

  ProjectEditState? editStateFor(String id) {
    final project = _projects[id];
    if (project == null) return null;
    return ProjectEditState(
      project: project,
      revision: revisionFor(id),
      editCounter: _editVersions[id] ?? 0,
      isDirty: _dirty.contains(id),
      isSaving: _saving.contains(id),
      error: _saveErrors[id],
    );
  }

  ProjectSaveState saveStateFor(String id) =>
      editStateFor(id)?.saveState ?? ProjectSaveState.saved;

  bool canDiscardDraft(String id) =>
      !_saving.contains(id) &&
      !_deleting.contains(id) &&
      (_remoteDeletions.contains(id) ||
          (_pendingRemote[id]?.revision ?? 0) > revisionFor(id));

  /// Used only after the user confirms discarding a conflicting draft.
  void discardConflictingDraft(String id) {
    if (_disposed || !canDiscardDraft(id)) {
      throw StateError('An acknowledged cloud version is not available yet.');
    }
    final remote = _pendingRemote.remove(id);
    _dirty.remove(id);
    _saveErrors.remove(id);
    if (_remoteDeletions.remove(id)) {
      _removeProject(id, selectNext: false);
    } else {
      final existing = _projects[id];
      if (existing != null) _observedContents[id] = _contents(existing);
      _acceptRemote(remote!);
    }
    _notifyIfActive();
  }

  List<SavedProject> get projects => _sortedProjects ??= UnmodifiableListView(
    _projects.values.toList()..sort((a, b) {
      final byDate = b.updatedAt.compareTo(a.updatedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    }),
  );

  /// Attaches once and completes when the first result or loading error arrives.
  /// A subsequent call after an error retries without discarding existing data.
  Future<void> load() {
    if (_disposed) return Future.error(StateError('Workspace is disposed.'));
    if (_loadFuture != null && _loadError == null) return _loadFuture!;
    final generation = ++_loadGeneration;
    final first = Completer<void>();
    _initialLoad = first;
    _loadFuture = first.future;
    _loadError = null;
    _notifyIfActive();
    unawaited(_subscribe(generation, first));
    return first.future;
  }

  Future<void> _subscribe(int generation, Completer<void> first) async {
    try {
      await _projectsSubscription?.cancel();
      if (_disposed || generation != _loadGeneration) return;
      _projectsSubscription = repository.watchProjects().listen(
        (page) {
          if (_disposed || generation != _loadGeneration) return;
          final firstPage = !_isLoaded;
          for (final record in page) {
            _acceptRemote(record);
          }
          // A bounded query losing a document does not establish its deletion.
          _isLoaded = true;
          _loadError = null;
          if (firstPage && _selectedProjectId == null && _projects.isNotEmpty) {
            _select(projects.first.id);
          }
          if (!first.isCompleted) first.complete();
          _notifyIfActive();
        },
        onError: (Object error, StackTrace stack) {
          if (_disposed || generation != _loadGeneration) return;
          _loadError = error;
          if (!first.isCompleted) first.complete();
          _notifyIfActive();
        },
      );
    } catch (error) {
      if (!_disposed && generation == _loadGeneration) {
        _loadError = error;
        if (!first.isCompleted) first.complete();
        _notifyIfActive();
      }
    }
  }

  Future<SavedProject> createProject() async {
    _requireLoaded();
    final now = DateTime.now().toUtc();
    final project = SavedProject(
      id: repository.newProjectId(),
      createdAt: now,
      updatedAt: now,
      formModel: ProjectFormModel(),
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

  Future<void> selectProject(String projectId) async {
    if (_disposed || !_projects.containsKey(projectId)) return;
    if (_selectedProjectId == projectId) return;
    _select(projectId);
    _notifyIfActive();
  }

  /// Records direct matrix/map edits without waiting for an explicit save call.
  void markProjectChanged(String id) {
    final project = _projects[id];
    if (_disposed || project == null || !_captureChanges(project)) return;
    project.touch();
    _notifyIfActive();
    _scheduleSave();
  }

  void _select(String? id) {
    _selectedProjectId = id;
    final generation = ++_selectionGeneration;
    unawaited(_selectedSubscription?.cancel());
    _selectedSubscription = null;
    if (id == null || _disposed) return;
    _selectedSubscription = repository
        .watchProject(id)
        .listen(
          (record) {
            if (_disposed || generation != _selectionGeneration) return;
            if (_deleting.contains(id)) return;
            if (record != null) {
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
            if (_disposed || generation != _selectionGeneration) return;
            _loadError = error;
            _notifyIfActive();
          },
        );
  }

  void _acceptRemote(CloudProject record) {
    final id = record.project.id;
    if (_deleting.contains(id) || record.hasPendingWrites) return;
    final existing = _projects[id];
    if (existing != null) _captureChanges(existing);
    if (_dirty.contains(id) || _saving.contains(id)) {
      final pending = _pendingRemote[id];
      if (pending == null || record.revision >= pending.revision) {
        _pendingRemote[id] = record;
      }
      return;
    }
    if (record.revision < revisionFor(id)) return;
    if (existing != null && _contents(existing) == _contents(record.project)) {
      existing.updatedAt = record.project.updatedAt;
    } else {
      _detachProjectListener(id);
      _projects[id] = record.project;
      _attachProjectListener(record.project);
    }
    _revisions[id] = record.revision;
    _observedContents[id] = _contents(_projects[id]!);
    _sortedProjects = null;
  }

  Future<bool> deleteProject(String projectId) async {
    _requireLoaded();
    if (!_projects.containsKey(projectId) || _deleting.contains(projectId)) {
      return false;
    }
    _deleting.add(projectId);
    var deletedSelection = false;
    try {
      await _enqueue(() async {
        if (_disposed) throw StateError('Workspace is disposed.');
        await repository.deleteProject(
          projectId,
          expectedRevision: revisionFor(projectId),
        );
        if (_disposed) return;
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

  /// Keeps the existing widget contract, including direct matrix/map mutations.
  Future<void> persistSelectedProject({bool markModified = false}) async {
    if (_disposed) return;
    final project = selectedProject;
    if (project == null) return;
    _syncSetupComplete(project);
    if (markModified) project.touch();
    _captureChanges(project);
    _notifyIfActive();
    await _queueSave(project.id);
  }

  Future<bool> completeProjectSetup() async {
    final project = selectedProject;
    if (project == null || !project.formModel.isSetupValid) return false;
    if (!project.setupComplete) {
      project.setupComplete = true;
      project.touch();
      _captureChanges(project);
    }
    await _queueSave(project.id);
    _notifyIfActive();
    return true;
  }

  /// A successful flush means every currently dirty project was acknowledged.
  Future<void> flush() async {
    _requireLoaded();
    _saveDebounceTimer?.cancel();
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

  Future<void> _queueSave(String id) => _enqueue(() => _saveProject(id));

  Future<void> _saveProject(String id) async {
    if (_disposed || _deleting.contains(id)) return;
    final project = _projects[id];
    if (project == null) return;
    _captureChanges(project);
    if (!_dirty.contains(id)) return;
    final version = _editVersions[id];
    final expectedRevision = revisionFor(id);
    final snapshot = SavedProject.fromJson(
      jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
    );
    _saving.add(id);
    _saveErrors.remove(id);
    _notifyIfActive();
    try {
      final revision = await repository.saveProject(
        snapshot,
        expectedRevision: expectedRevision,
      );
      if (_disposed) return;
      _revisions[id] = revision;
      _captureChanges(project);
      if (_editVersions[id] == version) {
        _dirty.remove(id);
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
        _scheduleSave();
      }
    } catch (error) {
      if (!_disposed) _saveErrors[id] = error;
      rethrow;
    } finally {
      _saving.remove(id);
      _notifyIfActive();
    }
  }

  // Only domain content is compared: server updatedAt acknowledgement is not an edit.
  String _contents(SavedProject project) => jsonEncode(
    _canonical(
      Map<String, dynamic>.from(project.toJson())..remove('updatedAt'),
    ),
  );

  Object? _canonical(Object? value) {
    if (value is Map<String, dynamic>) {
      final keys = value.keys.toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
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
  }

  void _attachProjectListener(SavedProject project) {
    _detachProjectListener(project.id);
    void listener() {
      if (_disposed) return;
      project.touch();
      _syncSetupComplete(project);
      _captureChanges(project);
      _notifyIfActive();
      _scheduleSave();
    }

    _projectListeners[project.id] = listener;
    project.formModel.addListener(listener);
  }

  void _detachProjectListener(String id) {
    final listener = _projectListeners.remove(id);
    if (listener != null) _projects[id]?.formModel.removeListener(listener);
  }

  void _removeProject(String id, {bool selectNext = true}) {
    _detachProjectListener(id);
    _projects.remove(id);
    _revisions.remove(id);
    _editVersions.remove(id);
    _observedContents.remove(id);
    _dirty.remove(id);
    _saveErrors.remove(id);
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

  void _scheduleSave() {
    if (_disposed) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(saveDebounce, _saveInBackground);
  }

  void _saveInBackground() {
    if (_disposed || !_isLoaded) return;
    unawaited(
      flush().catchError((Object _, StackTrace _) {
        // Per-project failures remain observable via saveErrorFor/saveStateFor.
      }),
    );
  }

  void _requireLoaded() {
    if (_disposed) throw StateError('Workspace is disposed.');
    if (!_isLoaded) throw StateError('The workspace is still loading.');
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
    _loadGeneration++;
    _selectionGeneration++;
    _saveDebounceTimer?.cancel();
    unawaited(_projectsSubscription?.cancel());
    unawaited(_selectedSubscription?.cancel());
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
    if (!_disposed) notifyListeners();
  }
}
