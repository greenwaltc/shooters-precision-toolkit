import 'dart:async';
import 'dart:convert';

import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/project_repository.dart';

/// An account-scoped, revision-aware backend with no Firebase initialization.
class FakeProjectRepository implements ProjectRepository {
  final _records = <String, CloudProject>{};
  final _changes = StreamController<void>.broadcast(sync: true);
  int _nextId = 0;
  final savedIds = <String>[];
  final deletedIds = <String>[];
  Future<void>? saveBarrier;
  Object? saveFailure;
  Object? deleteFailure;

  @override
  String newProjectId() => 'project_${++_nextId}';

  SavedProject _copy(SavedProject project) => SavedProject.fromJson(
    jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
  );

  CloudProject _copyRecord(CloudProject record) =>
      CloudProject(_copy(record.project), record.revision, false);

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((listener) {
    final subscription = _changes.stream.listen(
      (_) => listener.add(read()),
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.add(read());
    listener.onCancel = subscription.cancel;
  });

  @override
  Stream<List<CloudProject>> watchProjects() => _watch(() {
    final records = _records.values.toList()
      ..sort((a, b) {
        final date = b.project.updatedAt.compareTo(a.project.updatedAt);
        return date != 0 ? date : b.project.id.compareTo(a.project.id);
      });
    return records.take(25).map(_copyRecord).toList();
  });

  @override
  Future<List<CloudProject>> fetchOlderProjects({
    required CloudProject after,
  }) async {
    final records = _records.values.toList()
      ..sort((a, b) {
        final date = b.project.updatedAt.compareTo(a.project.updatedAt);
        return date != 0 ? date : b.project.id.compareTo(a.project.id);
      });
    return records
        .where((record) {
          final date = record.project.updatedAt.compareTo(
            after.project.updatedAt,
          );
          return date < 0 ||
              (date == 0 && record.project.id.compareTo(after.project.id) < 0);
        })
        .take(ProjectRepository.pageSize)
        .map(_copyRecord)
        .toList();
  }

  @override
  Stream<CloudProject?> watchProject(String id) => _watch(() {
    final record = _records[id];
    return record == null ? null : _copyRecord(record);
  });

  @override
  Future<int> saveProject(
    SavedProject project, {
    required int expectedRevision,
  }) async {
    final snapshot = _copy(project);
    await saveBarrier;
    if (saveFailure != null) throw saveFailure!;
    final current = _records[project.id];
    if ((current?.revision ?? 0) != expectedRevision) {
      throw ProjectConflict(project.id);
    }
    final saved = SavedProject.fromJson(
      snapshot.toJson()
        ..['createdAt'] = (current?.project.createdAt ?? snapshot.createdAt)
            .toIso8601String()
        ..['updatedAt'] = DateTime.now().toUtc().toIso8601String(),
    );
    final revision = expectedRevision + 1;
    _records[project.id] = CloudProject(saved, revision, false);
    savedIds.add(project.id);
    _changes.add(null);
    return revision;
  }

  @override
  Future<void> deleteProject(String id, {required int expectedRevision}) async {
    if (deleteFailure != null) throw deleteFailure!;
    final current = _records[id];
    if (current != null && current.revision != expectedRevision) {
      throw ProjectConflict(id);
    }
    _records.remove(id);
    deletedIds.add(id);
    _changes.add(null);
  }

  void emitError(Object error) => _changes.addError(error);
  Future<void> dispose() => _changes.close();
}
