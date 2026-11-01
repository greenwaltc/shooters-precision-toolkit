import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;

import '../model/saved_project.dart';

class ProjectConflict implements Exception {
  ProjectConflict(this.projectId);
  final String projectId;
}

/// A project and the persistence metadata used for conditional writes.
class CloudProject {
  CloudProject(
    this.project,
    this.revision,
    this.hasPendingWrites, {
    this.snapshot,
  });

  final SavedProject project;
  final int revision;
  final bool hasPendingWrites;

  /// Firestore pagination cursor, absent for an in-memory repository.
  final DocumentSnapshot<Map<String, dynamic>>? snapshot;
}

/// The workspace's persistence contract. Each instance belongs to one account.
abstract interface class ProjectRepository {
  String newProjectId();
  Stream<List<CloudProject>> watchProjects();
  Stream<CloudProject?> watchProject(String id);
  Future<int> saveProject(
    SavedProject project, {
    required int expectedRevision,
  });
  Future<void> deleteProject(String id, {required int expectedRevision});
}
