import '../api/project_draft_storage.dart';

export '../api/project_draft_storage.dart'
    show ProjectDraft, ProjectDraftStorage;

/// Draft storage for one workspace session.
///
/// Drafts remain in memory and disappear when the storage instance is
/// discarded.
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
