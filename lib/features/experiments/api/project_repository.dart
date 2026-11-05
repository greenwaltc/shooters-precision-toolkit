import 'dart:collection';

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/foundation/behavior_policy.dart';
import 'project_snapshot.dart';

export 'project_snapshot.dart' show ProjectDocument, ProjectSnapshot;

abstract interface class ProjectCursor {}

class ProjectConflict extends AppFailure {
  ProjectConflict(this.projectId) : super(FailureKind.conflict);
  final String projectId;
}

/// A project and the persistence metadata used for conditional writes.
class CloudProject {
  CloudProject(
    ProjectDocument project,
    this.revision,
    this.hasPendingWrites, {
    this.cursor,
    this.isFromCache = false,
  }) : project = project.freeze();

  final ProjectSnapshot project;
  final int revision;
  final bool hasPendingWrites;
  final bool isFromCache;

  /// Opaque adapter-owned position. Consumers must not interpret its content.
  final ProjectCursor? cursor;
}

/// The workspace's persistence contract. Each instance belongs to one account.
abstract interface class ProjectRepository {
  static const pageSize = BehaviorPolicy.projectsPageSize;
  String newProjectId();
  Stream<ProjectPage> watchProjects();
  Future<List<CloudProject>> fetchOlderProjects({required CloudProject after});
  Stream<CloudProject?> watchProject(String id);
  Future<int> saveProject(
    ProjectDocument project, {
    required int expectedRevision,
  });
  Future<void> deleteProject(String id, {required int expectedRevision});
}

/// Read-only bounded page, including authority even when it contains no records.
final class ProjectPage extends UnmodifiableListView<CloudProject> {
  ProjectPage(Iterable<CloudProject> records, {this.isFromCache = false})
    : super(List.of(records));
  final bool isFromCache;
}
