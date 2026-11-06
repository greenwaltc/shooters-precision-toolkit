import 'dart:collection';

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/foundation/behavior_policy.dart';
import 'project_snapshot.dart';

export 'project_snapshot.dart' show ProjectDocument, ProjectSnapshot;

/// An opaque position used to fetch the next page of projects from the same
/// repository.
abstract interface class ProjectCursor {}

/// A write rejected because the saved project no longer matches the expected
/// version.
class ProjectConflict extends AppFailure {
  /// Creates a conflict for the project identified by [projectId].
  ProjectConflict(this.projectId) : super(FailureKind.conflict);
  final String projectId;
}

/// A project and the persistence metadata used for conditional writes.
class CloudProject {
  /// Freezes [project] and records the revision and source of that snapshot.
  ///
  /// A cache result may be stale, and pending writes have not yet been
  /// acknowledged.
  CloudProject(
    ProjectDocument project,
    this.revision,
    this.hasPendingWrites, {
    this.cursor,
    this.isFromCache = false,
    this.editorSession,
  }) : project = project.freeze();

  final ProjectSnapshot project;
  final int revision;
  final bool hasPendingWrites;
  final bool isFromCache;

  /// Opaque workspace session that currently holds editing control, if any.
  final String? editorSession;

  /// Opaque adapter-owned position. Consumers must not interpret its content.
  final ProjectCursor? cursor;
}

/// A repository that coordinates editing between sessions of one account.
abstract interface class ProjectEditingRepository implements ProjectRepository {
  /// An opaque identifier unique to this workspace instance.
  String get editingSessionId;

  /// Claims editing of [id] and returns the acknowledged project.
  ///
  /// A new claim advances the revision without changing the project contents.
  /// With [allowTakeover] disabled, a competing claim stays in place and the
  /// returned project describes its holder. A missing project completes with
  /// [ProjectConflict]. Saves require both the current claim and revision.
  Future<CloudProject> claimEditing(String id, {required bool allowTakeover});
}

/// The workspace's persistence contract. Each instance belongs to one account.
abstract interface class ProjectRepository {
  static const pageSize = BehaviorPolicy.projectsPageSize;

  /// Creates a project ID without writing a project.
  String newProjectId();

  /// Watches the most recently updated page of projects.
  ///
  /// Page metadata identifies cache results, including an empty cache that
  /// cannot confirm there are no projects.
  Stream<ProjectPage> watchProjects();

  /// Fetches older projects after [after] using its repository cursor.
  ///
  /// Pass a record from the same repository. An empty result means no further
  /// records were returned.
  Future<List<CloudProject>> fetchOlderProjects({required CloudProject after});

  /// Watches the project identified by [id].
  ///
  /// A null result means the document was not found or was deleted.
  Stream<CloudProject?> watchProject(String id);

  /// Saves a snapshot of [project] if [expectedRevision] matches and returns
  /// the new revision.
  ///
  /// Use revision zero for a new project. A mismatch completes the future with
  /// [ProjectConflict].
  Future<int> saveProject(
    ProjectDocument project, {
    required int expectedRevision,
  });

  /// Deletes [id] if [expectedRevision] matches the saved version.
  ///
  /// A mismatch completes the future with [ProjectConflict].
  Future<void> deleteProject(String id, {required int expectedRevision});
}

/// Read-only bounded page, including authority even when it contains no records.
final class ProjectPage extends UnmodifiableListView<CloudProject> {
  /// Copies [records] into a read-only page.
  ///
  /// Set [isFromCache] when the result cannot yet confirm the server's current
  /// contents.
  ProjectPage(Iterable<CloudProject> records, {this.isFromCache = false})
    : super(List.of(records));
  final bool isFromCache;
}
