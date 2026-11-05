import 'dart:convert';

import '../../../shared/foundation/json_object.dart';
import 'project_snapshot.dart';

/// An immutable editing snapshot and the cloud revision it was based on.
class ProjectDraft {
  /// Captures [project] as it exists now, along with its expected cloud
  /// revision and local edit counter.
  ProjectDraft.capture(
    ProjectDocument project,
    this.expectedRevision,
    this.editCounter,
  ) : projectJson = jsonEncode(project.freeze().toJson());

  final String projectJson;
  final int expectedRevision;
  final int editCounter;

  /// The frozen project represented by the draft.
  ProjectSnapshot get project =>
      ProjectSnapshot.fromJson(decodeJsonObject(projectJson));

  /// Whether [other] has the same project contents, expected revision, and edit
  /// counter.
  bool matches(ProjectDraft other) =>
      expectedRevision == other.expectedRevision &&
      editCounter == other.editCounter &&
      projectJson == other.projectJson;
}

/// Storage for pending edits keyed by project ID.
///
/// Implementations must allow a completed save to remove its own draft without
/// removing later edits.
abstract interface class ProjectDraftStorage {
  /// Reads the current drafts keyed by project ID.
  Future<Map<String, ProjectDraft>> readAll();

  /// Stores [draft] as the pending version for [id], replacing any earlier
  /// draft for that ID.
  Future<void> write(String id, ProjectDraft draft);

  /// Removes the current draft for [id] if present.
  Future<void> remove(String id);

  /// Conditional acknowledgement cleanup; explicit deletion/discard uses remove.
  Future<bool> removeIfMatches(String id, ProjectDraft acknowledged);
}
