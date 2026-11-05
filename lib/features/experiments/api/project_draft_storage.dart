import 'dart:convert';

import '../../../shared/foundation/json_object.dart';
import 'project_snapshot.dart';

/// An immutable editing snapshot and the cloud revision it was based on.
class ProjectDraft {
  ProjectDraft.capture(
    ProjectDocument project,
    this.expectedRevision,
    this.editCounter,
  ) : projectJson = jsonEncode(project.freeze().toJson());

  final String projectJson;
  final int expectedRevision;
  final int editCounter;
  ProjectSnapshot get project =>
      ProjectSnapshot.fromJson(decodeJsonObject(projectJson));

  bool matches(ProjectDraft other) =>
      expectedRevision == other.expectedRevision &&
      editCounter == other.editCounter &&
      projectJson == other.projectJson;
}

abstract interface class ProjectDraftStorage {
  Future<Map<String, ProjectDraft>> readAll();
  Future<void> write(String id, ProjectDraft draft);
  Future<void> remove(String id);

  /// Conditional acknowledgement cleanup; explicit deletion/discard uses remove.
  Future<bool> removeIfMatches(String id, ProjectDraft acknowledged);
}
