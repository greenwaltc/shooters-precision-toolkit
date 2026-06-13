// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../storage/project_storage.dart';
import 'project_form_model.dart';
import 'saved_project.dart';

/// Coordinates project selection, persistence, and form-model listeners.
class ProjectStore extends ChangeNotifier with WidgetsBindingObserver {
  ProjectStore({required this.storage}) {
    WidgetsBinding.instance.addObserver(this);
  }

  final ProjectStorage storage;

  final List<SavedProject> _projects = [];
  final Map<String, VoidCallback> _projectListeners = {};
  UnmodifiableListView<SavedProject>? _sortedProjects;
  Future<void> _saveOperation = Future.value();
  Timer? _saveDebounceTimer;
  bool _isLoaded = false;
  String? _selectedProjectId;

  /// Whether projects have been loaded from storage.
  bool get isLoaded => _isLoaded;

  /// Projects sorted by most recently updated first.
  List<SavedProject> get projects {
    return _sortedProjects ??= UnmodifiableListView(_projectsByRecentUpdate());
  }

  /// Currently selected project, if one is available.
  SavedProject? get selectedProject {
    final selectedProjectId = _selectedProjectId;
    if (selectedProjectId == null) return null;

    for (final project in _projects) {
      if (project.id == selectedProjectId) return project;
    }

    return null;
  }

  /// Loads persisted projects once and selects the newest available project.
  Future<void> load() async {
    if (_isLoaded) return;

    final projectsJson = await storage.readProjectsJson();
    _projects
      ..clear()
      ..addAll(_decodeProjects(projectsJson));
    _invalidateProjectOrder();

    for (final project in _projects) {
      _attachProjectListener(project);
      _syncSetupComplete(project);
    }

    final selectedProjectExists = _projects.any(
      (project) => project.id == _selectedProjectId,
    );
    if (!selectedProjectExists) {
      _selectedProjectId = _projects.isEmpty ? null : projects.first.id;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Creates, selects, persists, and returns a new project.
  Future<SavedProject> createProject() async {
    final now = DateTime.now().toUtc();
    final project = SavedProject(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      formModel: ProjectFormModel(),
    );

    _projects.add(project);
    _invalidateProjectOrder();
    _selectedProjectId = project.id;
    _attachProjectListener(project);
    await _saveProjects();
    notifyListeners();

    return project;
  }

  /// Selects an existing project by id.
  Future<void> selectProject(String projectId) async {
    final projectExists = _projects.any((project) => project.id == projectId);
    if (!projectExists || _selectedProjectId == projectId) return;

    _selectedProjectId = projectId;
    notifyListeners();
  }

  /// Deletes a project and returns whether the selected project was removed.
  Future<bool> deleteProject(String projectId) async {
    final projectIndex = _projects.indexWhere(
      (project) => project.id == projectId,
    );
    if (projectIndex == -1) return false;

    final deletedProject = _projects.removeAt(projectIndex);
    _invalidateProjectOrder();
    final listener = _projectListeners.remove(deletedProject.id);
    if (listener != null) {
      deletedProject.formModel.removeListener(listener);
    }

    final deletedSelectedProject = _selectedProjectId == deletedProject.id;
    if (deletedSelectedProject) {
      _selectedProjectId = _projects.isEmpty ? null : projects.first.id;
    }

    await _saveProjects();
    notifyListeners();

    return deletedSelectedProject;
  }

  /// Persists the selected project, optionally marking it modified first.
  Future<void> persistSelectedProject({bool markModified = false}) async {
    if (markModified) {
      selectedProject?.touch();
      _invalidateProjectOrder();
    }
    await _saveProjects();
    if (markModified) notifyListeners();
  }

  /// Marks the selected project's setup form as submitted, unlocking the
  /// ANOMR matrix for that project. Returns whether the project may proceed
  /// to the matrix (including when setup was already complete and still valid).
  Future<bool> completeProjectSetup() async {
    final project = selectedProject;
    if (project == null) return false;
    if (!project.formModel.isSetupValid) return false;

    if (project.setupComplete) return true;

    project.setupComplete = true;
    project.touch();
    _invalidateProjectOrder();
    await _saveProjects();
    notifyListeners();
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(persistSelectedProject());
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    for (final project in _projects) {
      final listener = _projectListeners[project.id];
      if (listener != null) project.formModel.removeListener(listener);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncSetupComplete(SavedProject project) {
    if (!project.setupComplete || project.formModel.isSetupValid) return;

    project.setupComplete = false;
  }

  List<SavedProject> _projectsByRecentUpdate() {
    return [..._projects]..sort((first, second) {
      return second.updatedAt.compareTo(first.updatedAt);
    });
  }

  void _invalidateProjectOrder() {
    _sortedProjects = null;
  }

  List<SavedProject> _decodeProjects(String? projectsJson) {
    if (projectsJson == null || projectsJson.isEmpty) return [];

    final Object? decoded;
    try {
      decoded = jsonDecode(projectsJson);
    } on FormatException {
      return [];
    }
    final projectItems = decoded is Map<String, dynamic>
        ? decoded['projects']
        : decoded;

    if (decoded is Map<String, dynamic>) {
      _selectedProjectId = decoded['selectedProjectId'] as String?;
    }

    if (projectItems is! List) return [];

    return projectItems.whereType<Map>().map((projectJson) {
      return SavedProject.fromJson(Map<String, dynamic>.from(projectJson));
    }).toList();
  }

  void _attachProjectListener(SavedProject project) {
    final oldListener = _projectListeners.remove(project.id);
    if (oldListener != null) {
      project.formModel.removeListener(oldListener);
    }

    void listener() {
      project.touch();
      _invalidateProjectOrder();
      _syncSetupComplete(project);
      notifyListeners();
      _scheduleSave();
    }

    project.formModel.addListener(listener);
    _projectListeners[project.id] = listener;
  }

  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_saveProjects());
    });
  }

  Future<void> _saveProjects() {
    final payload = jsonEncode({
      'version': 1,
      'selectedProjectId': _selectedProjectId,
      'projects': _projects.map((project) => project.toJson()).toList(),
    });

    _saveOperation = _saveOperation
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('ProjectStore: failed to save projects: $error');
        })
        .then((_) => storage.writeProjectsJson(payload));
    return _saveOperation;
  }
}
