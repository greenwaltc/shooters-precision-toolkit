import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/saved_project.dart';

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
      SavedProject.fromJson(jsonDecode(projectJson) as Map<String, dynamic>);

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
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('A project draft must be a JSON object.');
    }
    final data = decoded;
    if (data['schemaVersion'] != 1 ||
        data['project'] is! Map<String, dynamic> ||
        data['project']['id'] is! String ||
        (data['project']['id'] as String).isEmpty ||
        data['expectedRevision'] is! int ||
        (data['expectedRevision'] as int) < 0 ||
        data['editCounter'] is! int ||
        (data['editCounter'] as int) < 1) {
      throw const FormatException('Unsupported local project draft.');
    }
    return ProjectDraft._(
      jsonEncode(data['project']),
      data['expectedRevision'] as int,
      data['editCounter'] as int,
    );
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
    if (current == null || !current.matches(acknowledged)) return false;
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
      final draft = ProjectDraft.decode(preferences.getString(key)!);
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
    final value = preferences.getString(_key(id));
    if (value == null || !ProjectDraft.decode(value).matches(acknowledged)) {
      return false;
    }
    if (!await preferences.remove(_key(id))) {
      throw StateError('Unable to clear the acknowledged project draft.');
    }
    return true;
  }
}
