import 'dart:async';

import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/project_draft_storage.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'matrix/randomization edits record drafts now and upload once after idle',
    () => _withClock((time, f) {
      f.project.matrixState['range_0'] = '1';
      _finish(time, f.store.persistSelectedProject());
      expect(
        _finish(
          time,
          f.drafts.readAll(),
        )[f.project.id]!.project.matrixState['range_0'],
        '1',
      );
      expect(f.repository.attempts, isEmpty);
      time.elapse(const Duration(seconds: 1));
      f.project.matrixState['range_0'] = '1.25';
      f.project.randomizeOrder = true;
      f.project.randomizeSequence = [1, 0];
      _finish(time, f.store.persistSelectedProject());
      time.elapse(const Duration(seconds: 1));
      expect(f.repository.attempts, isEmpty);
      time.elapse(const Duration(seconds: 1));
      expect(f.repository.attempts, [f.project.id]);
      expect(f.store.revisionFor(f.project.id), 2);
      expect(f.store.hasUnsavedChanges, isFalse);
      expect(_finish(time, f.drafts.readAll()), isEmpty);
      final saved = f.repository.acknowledged[f.project.id]!;
      expect(saved.matrixState['range_0'], '1.25');
      expect(saved.randomizeSequence, [1, 0]);
      time.elapse(const Duration(seconds: 20));
      expect(f.repository.attempts, [f.project.id]);
    }),
  );

  test(
    'each project has an independent debounce timer',
    () => _withClock((time, f) {
      final second = _finish(time, f.store.createProject());
      f.repository.attempts.clear();
      f.project.formModel.setProjectTitle('First edit');
      time.elapse(const Duration(seconds: 1));
      second.formModel.setProjectTitle('Second edit');
      time.elapse(const Duration(seconds: 1));
      expect(f.repository.attempts, [f.project.id]);
      time.elapse(const Duration(seconds: 1));
      expect(f.repository.attempts, [f.project.id, second.id]);
      expect(f.repository.maximumConcurrentSaves, 1);
    }),
  );

  test(
    'simultaneous autosaves queue behind a slow save',
    () => _withClock((time, f) {
      final second = _finish(time, f.store.createProject());
      f.repository.attempts.clear();
      final barrier = Completer<void>();
      f.repository.saveBarrier = barrier.future;
      f.project.formModel.setProjectTitle('First');
      second.formModel.setProjectTitle('Second');
      time.elapse(const Duration(seconds: 2));
      expect(f.repository.attempts, [f.project.id]);
      barrier.complete();
      time.flushMicrotasks();
      expect(f.repository.attempts, [f.project.id, second.id]);
      expect(f.repository.maximumConcurrentSaves, 1);
    }),
  );

  test(
    'failed automatic saves stay paused through edits/lifecycle events until retry',
    () => _withClock((time, f) {
      f.repository.saveFailure = StateError('offline');
      f.project.formModel.setProjectTitle('First draft');
      time.elapse(const Duration(seconds: 2));
      expect(f.repository.attempts, [f.project.id]);
      expect(f.store.saveStateFor(f.project.id), ProjectSaveState.error);
      f.project.formModel.setProjectTitle('Newer draft');
      f.store.didChangeAppLifecycleState(AppLifecycleState.inactive);
      time.elapse(const Duration(seconds: 30));
      expect(f.repository.attempts, [f.project.id]);
      expect(
        _finish(time, f.drafts.readAll())[f.project.id]!.project.displayName,
        'Newer draft',
      );
      f.repository.saveFailure = null;
      _finish(time, f.store.saveSelectedProject());
      expect(f.repository.attempts, [f.project.id, f.project.id]);
      expect(f.store.saveStateFor(f.project.id), ProjectSaveState.saved);
      expect(_finish(time, f.drafts.readAll()), isEmpty);
    }),
  );

  test(
    'a conflicted project does not block another autosave',
    () => _withClock((time, f) {
      final second = _finish(time, f.store.createProject());
      _finish(time, f.store.selectProject(f.project.id));
      final remote = ProjectDraft.capture(
        f.repository.acknowledged[f.project.id]!,
        1,
        1,
      ).project;
      f.project.formModel.setProjectTitle('Local draft');
      remote.formModel.setProjectTitle('Competing remote edit');
      _finish(time, f.repository.saveProject(remote, expectedRevision: 1));
      f.repository.attempts.clear();
      second.formModel.setProjectTitle('Other project still saves');
      time.elapse(const Duration(seconds: 2));
      expect(f.repository.attempts, [second.id]);
      expect(f.store.saveStateFor(f.project.id), ProjectSaveState.conflict);
      expect(
        _finish(time, f.drafts.readAll())[f.project.id]!.project.displayName,
        'Local draft',
      );
      time.elapse(const Duration(seconds: 20));
      expect(f.repository.attempts, [second.id]);
    }),
  );

  test(
    'unsaved drafts recover with their original revision after reopening',
    () => _withClock((time, f) {
      f.project.formModel.setProjectTitle('Recover after restart');
      _finish(time, f.store.persistSelectedProject());
      final counter = f.store.editStateFor(f.project.id)!.editCounter;
      final restored = ProjectStore(
        repository: f.repository,
        draftStorage: f.drafts,
      );
      try {
        _finish(time, restored.load());
        expect(restored.selectedProject!.displayName, 'Recover after restart');
        expect(restored.revisionFor(f.project.id), 1);
        expect(restored.editStateFor(f.project.id)!.editCounter, counter);
        expect(restored.hasUnsavedChanges, isTrue);
        _finish(time, restored.saveSelectedProject());
        expect(restored.revisionFor(f.project.id), 2);
        expect(_finish(time, f.drafts.readAll()), isEmpty);
      } finally {
        restored.dispose();
      }
    }),
  );

  test(
    'draft write failure prevents cloud upload and can be retried explicitly',
    () => _withClock((time, f) {
      final cache = _FailingDraftStorage();
      final workspace = ProjectStore(
        repository: f.repository,
        draftStorage: cache,
      );
      try {
        _finish(time, workspace.load());
        final selected = workspace.selectedProject!;
        cache.failWrites = true;
        selected.formModel.setProjectTitle('Keep this edit');
        expect(
          () => _finish(time, workspace.persistSelectedProject()),
          throwsStateError,
        );
        expect(
          () => _finish(time, workspace.saveSelectedProject()),
          throwsStateError,
        );
        expect(f.repository.attempts, isEmpty);
        expect(workspace.hasUnsavedChanges, isTrue);
        cache.failWrites = false;
        _finish(time, workspace.saveSelectedProject());
        expect(f.repository.attempts, [selected.id]);
        expect(workspace.saveStateFor(selected.id), ProjectSaveState.saved);
      } finally {
        workspace.dispose();
      }
    }),
  );

  test(
    'newer in-flight drafts retain the acknowledged base revision',
    () => _withClock((time, f) {
      f.project.formModel.setProjectTitle('Submitted');
      final barrier = Completer<void>();
      f.repository.saveBarrier = barrier.future;
      final saving = f.store.saveSelectedProject();
      time.flushMicrotasks();
      f.project.formModel.setProjectTitle('Newer edit');
      barrier.complete();
      _finish(time, saving);
      final pending = _finish(time, f.drafts.readAll())[f.project.id]!;
      expect(pending.project.displayName, 'Newer edit');
      expect(pending.expectedRevision, 2);
      expect(f.store.hasUnsavedChanges, isTrue);
      _finish(time, f.store.saveSelectedProject());
      expect(f.store.revisionFor(f.project.id), 3);
      expect(_finish(time, f.drafts.readAll()), isEmpty);
    }),
  );
}

void _withClock(void Function(FakeAsync, _Fixture) test) => fakeAsync((time) {
  final fixture = _Fixture();
  _finish(time, fixture.initialize());
  try {
    test(time, fixture);
  } finally {
    fixture.store.dispose();
    _finish(time, fixture.repository.dispose());
  }
});

T _finish<T>(FakeAsync time, Future<T> future) {
  var completed = false;
  late T result;
  Object? failure;
  StackTrace? stack;
  future.then(
    (value) {
      result = value;
      completed = true;
    },
    onError: (Object error, StackTrace trace) {
      failure = error;
      stack = trace;
      completed = true;
    },
  );
  time.flushMicrotasks();
  time.elapse(Duration.zero); // Stream.first cancellation may use a zero timer.
  if (!completed) {
    throw StateError('Advance the clock or release the save barrier first.');
  }
  if (failure != null) Error.throwWithStackTrace(failure!, stack!);
  return result;
}

class _Fixture {
  final repository = _TrackingRepository();
  final drafts = InMemoryProjectDraftStorage();
  late final store = ProjectStore(repository: repository, draftStorage: drafts);
  late SavedProject project;
  Future<void> initialize() async {
    await store.load();
    project = await store.createProject();
    repository.attempts.clear();
    repository.savedIds.clear();
  }
}

class _TrackingRepository extends FakeProjectRepository {
  final attempts = <String>[];
  final acknowledged = <String, SavedProject>{};
  int _active = 0;
  int maximumConcurrentSaves = 0;
  @override
  Future<int> saveProject(
    SavedProject project, {
    required int expectedRevision,
  }) async {
    attempts.add(project.id);
    final frozen = ProjectDraft.capture(project, expectedRevision, 1).project;
    _active++;
    if (_active > maximumConcurrentSaves) maximumConcurrentSaves = _active;
    try {
      final revision = await super.saveProject(
        project,
        expectedRevision: expectedRevision,
      );
      acknowledged[project.id] = frozen;
      return revision;
    } finally {
      _active--;
    }
  }
}

class _FailingDraftStorage extends InMemoryProjectDraftStorage {
  bool failWrites = false;
  @override
  Future<void> write(String id, ProjectDraft draft) {
    if (failWrites) {
      return Future.error(StateError('Local storage unavailable'));
    }
    return super.write(id, draft);
  }
}
