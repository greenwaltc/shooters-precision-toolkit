import 'dart:async';

import 'package:bramwells_precision_test_kit/features/experiments/api/project_repository.dart';
import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/app_failure.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_project_repository.dart';

final class _FreshnessRepository extends FakeProjectRepository {
  _FreshnessRepository() {
    pages = StreamController<ProjectPage>.broadcast(
      sync: true,
      onListen: () => listening.complete(),
    );
  }
  late final StreamController<ProjectPage> pages;
  Completer<void> listening = Completer<void>();
  bool _closed = false;
  @override
  Stream<ProjectPage> watchProjects() => pages.stream;
  @override
  Stream<CloudProject?> watchProject(String id) => const Stream.empty();
  @override
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await pages.close();
    await super.dispose();
  }
}

void main() {
  const deadline = Duration(seconds: 5);
  test(
    'cached absence stays loading, times out safely, and can retry',
    () async {
      final repository = _FreshnessRepository();
      final store = ProjectStore(
        repository: repository,
        draftStorage: InMemoryProjectDraftStorage(),
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        initialLoadTimeout: Duration.zero,
      );
      addTearDown(store.dispose);
      final loading = store.load();
      await repository.listening.future.timeout(deadline);
      repository.pages.add(ProjectPage([], isFromCache: true));
      expect(store.loadState, WorkspaceLoadState.loading);
      expect(store.hasCurrentCloudData, isFalse);
      await loading.timeout(deadline);
      expect(store.loadState, WorkspaceLoadState.error);
      expect(
        store.loadError,
        isA<AppFailure>().having(
          (error) => error.kind,
          'kind',
          FailureKind.unavailable,
        ),
      );
      repository.listening = Completer<void>();
      final retry = store.load();
      await repository.listening.future.timeout(deadline);
      repository.pages.add(ProjectPage([]));
      await retry.timeout(deadline);
      expect(store.loadState, WorkspaceLoadState.empty);
      expect(store.hasCurrentCloudData, isTrue);
    },
  );

  test(
    'cached content remains usable and only server metadata marks it current',
    () async {
      final repository = _FreshnessRepository();
      final store = ProjectStore(
        repository: repository,
        draftStorage: InMemoryProjectDraftStorage(),
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      );
      addTearDown(store.dispose);
      final record = CloudProject(
        ProjectSnapshot.fromJson({
          'id': 'fixture',
          'createdAt': '2026-11-04T00:00:00Z',
          'updatedAt': '2026-11-04T00:00:00Z',
          'formModel': {'projectTitle': 'Cached fixture'},
          'matrixState': <String, Object?>{},
        }),
        1,
        false,
      );
      final loading = store.load();
      await repository.listening.future.timeout(deadline);
      repository.pages.add(ProjectPage([record], isFromCache: true));
      await loading.timeout(deadline);
      expect(store.projects.single.displayName, 'Cached fixture');
      expect(store.isProjectCurrent('fixture'), isFalse);
      repository.pages.add(ProjectPage([record]));
      expect(store.isProjectCurrent('fixture'), isTrue);
    },
  );
}
