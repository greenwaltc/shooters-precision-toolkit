import 'dart:async';

import 'package:clock/clock.dart';

import '../api/project_repository.dart';

/// Volatile adapter for assembled tests and previews. Production is cloud-only.
/// The creator injects time/IDs and closes the adapter after its consumers stop.
class EphemeralProjectRepository implements ProjectRepository {
  EphemeralProjectRepository({
    required Clock clock,
    required String Function() newId,
  }) : _clock = clock,
       _newId = newId;

  final Clock _clock;
  final String Function() _newId;
  final _records = <String, CloudProject>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  @override
  String newProjectId() => _newId();

  ProjectSnapshot _copy(ProjectDocument project) => project.freeze();
  CloudProject _record(CloudProject record) =>
      CloudProject(_copy(record.project), record.revision, false);
  List<CloudProject> get _ordered => _records.values.toList()
    ..sort((a, b) {
      final order = b.project.updatedAt.compareTo(a.project.updatedAt);
      return order != 0 ? order : b.project.id.compareTo(a.project.id);
    });

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((listener) {
    final subscription = _changes.stream.listen(
      (_) => listener.add(read()),
      onDone: listener.close,
      onError: listener.addError,
    );
    listener.add(read());
    listener.onCancel = subscription.cancel;
  });

  @override
  Stream<ProjectPage> watchProjects() => _watch(
    () => ProjectPage(_ordered.take(ProjectRepository.pageSize).map(_record)),
  );
  @override
  Stream<CloudProject?> watchProject(String id) => _watch(() {
    final record = _records[id];
    return record == null ? null : _record(record);
  });
  @override
  Future<List<CloudProject>> fetchOlderProjects({
    required CloudProject after,
  }) async => _ordered
      .where(
        (record) =>
            record.project.updatedAt.isBefore(after.project.updatedAt) ||
            (record.project.updatedAt == after.project.updatedAt &&
                record.project.id.compareTo(after.project.id) < 0),
      )
      .take(ProjectRepository.pageSize)
      .map(_record)
      .toList();

  @override
  Future<int> saveProject(
    ProjectDocument project, {
    required int expectedRevision,
  }) async {
    final existing = _records[project.id];
    if ((existing?.revision ?? 0) != expectedRevision) {
      throw ProjectConflict(project.id);
    }
    final saved = ProjectSnapshot.fromJson(
      _copy(project).toJson()
        ..['updatedAt'] = _clock.now().toUtc().toIso8601String(),
    );
    final revision = expectedRevision + 1;
    _records[project.id] = CloudProject(saved, revision, false);
    _changes.add(null);
    return revision;
  }

  @override
  Future<void> deleteProject(String id, {required int expectedRevision}) async {
    final current = _records[id];
    if (current != null && current.revision != expectedRevision) {
      throw ProjectConflict(id);
    }
    _records.remove(id);
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
