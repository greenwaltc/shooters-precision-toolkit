import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/saved_project.dart';
import '../util/json_object.dart';

/// An immutable editing snapshot and the cloud revision it was based on.
class ProjectDraft {
  ProjectDraft.capture(
    SavedProject project,
    this.expectedRevision,
    this.editCounter,
  ) : projectJson = jsonEncode(project.toJson());

  ProjectDraft._(this.projectJson, this.expectedRevision, this.editCounter);

  final String projectJson;
  final int expectedRevision;
  final int editCounter;
  SavedProject get project =>
      SavedProject.fromJson(decodeJsonObject(projectJson));

  String encode() => jsonEncode({
    'schemaVersion': 1,
    'project': jsonDecode(projectJson),
    'expectedRevision': expectedRevision,
    'editCounter': editCounter,
  });

  bool matches(ProjectDraft other) =>
      expectedRevision == other.expectedRevision &&
      editCounter == other.editCounter &&
      projectJson == other.projectJson;

  factory ProjectDraft.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('A project draft must be a JSON object.');
    }
    final data = decoded;
    final project = data['project'];
    final id = project is Map<String, Object?> ? project['id'] : null;
    final revision = data['expectedRevision'];
    final counter = data['editCounter'];
    if (data['schemaVersion'] != 1 ||
        project is! Map<String, Object?> ||
        id is! String ||
        id.isEmpty ||
        revision is! int ||
        revision < 0 ||
        counter is! int ||
        counter < 1) {
      throw const FormatException('Unsupported local project draft.');
    }
    return ProjectDraft._(jsonEncode(project), revision, counter);
  }
}

abstract interface class ProjectDraftStorage {
  Future<Map<String, ProjectDraft>> readAll();
  Future<void> write(String id, ProjectDraft draft);
  Future<void> remove(String id);

  /// Conditional acknowledgement cleanup; explicit deletion/discard uses remove.
  Future<bool> removeIfMatches(String id, ProjectDraft acknowledged);
}

class InMemoryProjectDraftStorage implements ProjectDraftStorage {
  final _drafts = <String, ProjectDraft>{};

  @override
  Future<Map<String, ProjectDraft>> readAll() async => Map.of(_drafts);
  @override
  Future<void> write(String id, ProjectDraft draft) async =>
      _drafts[id] = draft;
  @override
  Future<void> remove(String id) async => _drafts.remove(id);

  @override
  Future<bool> removeIfMatches(String id, ProjectDraft acknowledged) async {
    final current = _drafts[id];
    if (current == null || !current.matches(acknowledged)) {
      return false;
    }
    _drafts.remove(id);
    return true;
  }
}

/// Isolated from both legacy workspace JSON and other accounts/environments.
class SharedPreferencesProjectDraftStorage implements ProjectDraftStorage {
  SharedPreferencesProjectDraftStorage({
    required String projectId,
    required String uid,
  }) : _prefix =
           'project_drafts_v1/${Uri.encodeComponent(projectId)}/${Uri.encodeComponent(uid)}/';

  final String _prefix;
  String _key(String id) => '$_prefix${Uri.encodeComponent(id)}';

  @override
  Future<Map<String, ProjectDraft>> readAll() async {
    final preferences = await SharedPreferences.getInstance();
    final drafts = <String, ProjectDraft>{};
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_prefix),
    )) {
      final value = preferences.get(key);
      if (value is! String) {
        throw const FormatException('A stored project draft must be a string.');
      }
      final draft = ProjectDraft.decode(value);
      final id = Uri.decodeComponent(key.substring(_prefix.length));
      if (draft.project.id != id) {
        throw const FormatException('Draft ID mismatch.');
      }
      drafts[id] = draft;
    }
    return drafts;
  }

  @override
  Future<void> write(String id, ProjectDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key(id), draft.encode())) {
      throw StateError('Unable to save the local project draft.');
    }
  }

  @override
  Future<void> remove(String id) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(_key(id))) {
      throw StateError('Unable to clear the acknowledged project draft.');
    }
  }

  @override
  Future<bool> removeIfMatches(String id, ProjectDraft acknowledged) async {
    final preferences = await SharedPreferences.getInstance();
    // Refresh the legacy preferences cache before comparing persisted contents.
    await preferences.reload();
    final value = preferences.get(_key(id));
    if (value == null) {
      return false;
    }
    if (value is! String) {
      throw const FormatException('A stored project draft must be a string.');
    }
    if (!ProjectDraft.decode(value).matches(acknowledged)) {
      return false;
    }
    if (!await preferences.remove(_key(id))) {
      throw StateError('Unable to clear the acknowledged project draft.');
    }
    return true;
  }
}
