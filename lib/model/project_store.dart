// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../storage/project_storage.dart';
import 'project_form_model.dart';
import 'saved_project.dart';

class ProjectStore extends ChangeNotifier with WidgetsBindingObserver {
  ProjectStore({required this.storage}) {
    WidgetsBinding.instance.addObserver(this);
  }

  final ProjectStorage storage;

  final List<SavedProject> _projects = [];
  final Map<String, VoidCallback> _projectListeners = {};
  Future<void> _saveOperation = Future.value();
  bool _isLoaded = false;
  String? _selectedProjectId;

  bool get isLoaded => _isLoaded;

  List<SavedProject> get projects {
    return [..._projects]..sort((first, second) {
      return second.updatedAt.compareTo(first.updatedAt);
    });
  }

  SavedProject? get selectedProject {
    final selectedProjectId = _selectedProjectId;
    if (selectedProjectId == null) return null;

    for (final project in _projects) {
      if (project.id == selectedProjectId) return project;
    }

    return null;
  }

  Future<void> load() async {
    if (_isLoaded) return;

    final projectsJson = await storage.readProjectsJson();
    _projects
      ..clear()
      ..addAll(_decodeProjects(projectsJson));

    for (final project in _projects) {
      _attachProjectListener(project);
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

  Future<SavedProject> createProject() async {
    final now = DateTime.now().toUtc();
    final project = SavedProject(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      formModel: ProjectFormModel(),
    );

    _projects.add(project);
    _selectedProjectId = project.id;
    _attachProjectListener(project);
    await _saveProjects();
    notifyListeners();

    return project;
  }

  Future<void> selectProject(String projectId) async {
    final projectExists = _projects.any((project) => project.id == projectId);
    if (!projectExists || _selectedProjectId == projectId) return;

    _selectedProjectId = projectId;
    notifyListeners();
  }

  Future<bool> deleteProject(String projectId) async {
    final projectIndex = _projects.indexWhere(
      (project) => project.id == projectId,
    );
    if (projectIndex == -1) return false;

    final deletedProject = _projects.removeAt(projectIndex);
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

  Future<void> persistSelectedProject({bool markModified = false}) async {
    if (markModified) {
      selectedProject?.touch();
    }
    await _saveProjects();
    if (markModified) notifyListeners();
  }

  /// Marks the selected project's setup form as submitted, unlocking the
  /// ANOMR matrix for that project.
  Future<void> completeProjectSetup() async {
    final project = selectedProject;
    if (project == null || project.setupComplete) return;
    if (!project.formModel.isSetupValid) return;

    project.setupComplete = true;
    project.touch();
    await _saveProjects();
    notifyListeners();
  }

  void _syncSetupComplete(SavedProject project) {
    if (!project.setupComplete || project.formModel.isSetupValid) return;

    project.setupComplete = false;
  }

  Future<void> persistAllProjects() async {
    await _saveProjects();
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
    for (final project in _projects) {
      final listener = _projectListeners[project.id];
      if (listener != null) project.formModel.removeListener(listener);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      _syncSetupComplete(project);
      unawaited(_saveProjects());
      notifyListeners();
    }

    project.formModel.addListener(listener);
    _projectListeners[project.id] = listener;
  }

  Future<void> _saveProjects() {
    final payload = jsonEncode({
      'version': 1,
      'selectedProjectId': _selectedProjectId,
      'projects': _projects.map((project) => project.toJson()).toList(),
    });

    _saveOperation = _saveOperation
        .catchError((_) {})
        .then((_) => storage.writeProjectsJson(payload));
    return _saveOperation;
  }
}
