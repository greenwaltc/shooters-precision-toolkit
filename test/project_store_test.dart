import 'dart:async';

import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeProjectRepository repository;
  late ProjectStore store;
  setUp(() async {
    repository = FakeProjectRepository();
    store = ProjectStore(repository: repository);
    await store.load();
  });
  tearDown(() async {
    store.dispose();
    await repository.dispose();
  });

  test(
    'repository assigns IDs and new projects start at revision one',
    () async {
      final project = await store.createProject();
      expect(project.id, 'project_1');
      expect(store.revisionFor(project.id), 1);
      expect(store.saveStateFor(project.id), ProjectSaveState.saved);
    },
  );

  test('workspace distinguishes loading, empty, ready and errors', () async {
    final backend = FakeProjectRepository();
    final workspace = ProjectStore(repository: backend);
    expect(workspace.loadState, WorkspaceLoadState.loading);
    await workspace.load();
    expect(workspace.loadState, WorkspaceLoadState.empty);
    final project = await workspace.createProject();
    expect(workspace.loadState, WorkspaceLoadState.ready);
    backend.emitError(StateError('query failed'));
    await _events();
    expect(workspace.loadState, WorkspaceLoadState.error);
    expect(workspace.projects.single.id, project.id);
    await workspace.load();
    expect(workspace.loadState, WorkspaceLoadState.ready);
    workspace.dispose();
    await backend.dispose();
  });

  test('edit state captures metadata independently for each project', () async {
    final first = await store.createProject();
    final second = await store.createProject();
    final before = store.editStateFor(first.id)!;
    first.formModel.setProjectTitle('Edited');
    final after = store.editStateFor(first.id)!;
    expect(after.project, same(first));
    expect(after.revision, before.revision);
    expect(after.editCounter, before.editCounter + 1);
    expect(after.isDirty, isTrue);
    expect(after.isSaving, isFalse);
    expect(after.hasConflict, isFalse);
    expect(before.isDirty, isFalse);
    expect(store.editStateFor(second.id)!.saveState, ProjectSaveState.saved);
    await store.flush();
    expect(store.editStateFor(first.id)!.revision, before.revision + 1);
    expect(store.editStateFor(first.id)!.editCounter, after.editCounter);
    expect(store.editStateFor(first.id)!.isDirty, isFalse);
    expect(store.editStateFor('missing'), isNull);
  });

  test(
    'active matrix edits mark dirty once without starting an immediate write',
    () async {
      final project = await store.createProject();
      final before = store.editStateFor(project.id)!;
      repository.savedIds.clear();
      project.matrixState['range_0'] = '1.75';
      store.markProjectChanged(project.id);
      expect(
        store.editStateFor(project.id)!.editCounter,
        before.editCounter + 1,
      );
      expect(store.saveStateFor(project.id), ProjectSaveState.dirty);
      expect(repository.savedIds, isEmpty);
      store.markProjectChanged(project.id);
      expect(
        store.editStateFor(project.id)!.editCounter,
        before.editCounter + 1,
      );
      await store.flush();
      expect(repository.savedIds, [project.id]);
      expect(store.saveStateFor(project.id), ProjectSaveState.saved);
    },
  );

  test(
    'in-flight map edits automatically save after the older snapshot',
    () async {
      final backend = FakeProjectRepository();
      final workspace = ProjectStore(
        repository: backend,
        saveDebounce: const Duration(milliseconds: 20),
      );
      await workspace.load();
      final project = await workspace.createProject();
      project.formModel.setProjectTitle('Submitted');
      final barrier = Completer<void>();
      backend.saveBarrier = barrier.future;
      final saving = workspace.saveSelectedProject();
      await _events();
      final submitted = workspace.editStateFor(project.id)!;
      expect(submitted.isSaving, isTrue);
      // Direct matrix changes have no form-model notification or debounce timer.
      project.matrixState['range_0'] = '2.5';
      barrier.complete();
      await saving;
      final newer = workspace.editStateFor(project.id)!;
      expect(newer.revision, 2);
      expect(newer.editCounter, greaterThan(submitted.editCounter));
      expect(newer.isDirty, isTrue);
      expect(newer.isSaving, isFalse);
      expect(
        (await backend.watchProject(project.id).first)!.project.matrixState,
        isEmpty,
      );
      final saved = Completer<void>();
      void observe() {
        if (workspace.revisionFor(project.id) == 3 &&
            !workspace.hasUnsavedChanges) {
          if (!saved.isCompleted) saved.complete();
        }
      }

      workspace.addListener(observe);
      await saved.future.timeout(const Duration(seconds: 2));
      expect(
        (await backend.watchProject(project.id).first)!.project.matrixState,
        {'range_0': '2.5'},
      );
      expect(
        workspace.editStateFor(project.id)!.saveState,
        ProjectSaveState.saved,
      );
      workspace.dispose();
      await backend.dispose();
    },
  );

  test(
    'conflict can keep the draft or explicitly accept the cloud version',
    () async {
      final project = await store.createProject();
      final remote = (await repository.watchProject(project.id).first)!;
      project.formModel.setProjectTitle('Local draft');
      remote.project.formModel.setProjectTitle('Cloud version');
      await repository.saveProject(remote.project, expectedRevision: 1);
      await _events();
      await expectLater(
        store.saveSelectedProject(),
        throwsA(isA<ProjectConflict>()),
      );
      final conflict = store.editStateFor(project.id)!;
      expect(conflict.hasConflict, isTrue);
      expect(conflict.isDirty, isTrue);
      expect(conflict.project.displayName, 'Local draft');
      expect(store.canDiscardDraft(project.id), isTrue);
      store.discardConflictingDraft(project.id);
      expect(store.selectedProject!.displayName, 'Cloud version');
      expect(store.revisionFor(project.id), 2);
      expect(store.editStateFor(project.id)!.saveState, ProjectSaveState.saved);
    },
  );

  test(
    'initial subscription failure is observable and can be retried',
    () async {
      final failing = _InitiallyFailingRepository();
      final workspace = ProjectStore(repository: failing);
      await workspace.load();
      expect(workspace.isLoaded, isFalse);
      expect(workspace.loadError, isStateError);
      failing.fail = false;
      await workspace.load();
      expect(workspace.isLoaded, isTrue);
      expect(workspace.loadError, isNull);
      workspace.dispose();
      await failing.dispose();
    },
  );

  testWidgets('form changes coalesce after the debounce interval', (
    tester,
  ) async {
    final project = (await tester.runAsync(store.createProject))!;
    repository.savedIds.clear();
    project.formModel.setProjectTitle('A');
    await tester.pump(const Duration(seconds: 1));
    project.formModel.setProjectTitle('AB');
    await tester.pump(const Duration(seconds: 1));
    expect(repository.savedIds, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(repository.savedIds, [project.id]);
    expect(store.hasUnsavedChanges, isFalse);
  });

  test(
    'edits save only the changed project, unchanged flushes do not write',
    () async {
      final first = await store.createProject();
      final second = await store.createProject();
      repository.savedIds.clear();
      first.formModel.setProjectTitle('Only first changed');
      expect(store.hasUnsavedChanges, isTrue);
      await store.flush();
      expect(repository.savedIds, [first.id]);
      expect(store.revisionFor(first.id), 2);
      expect(store.revisionFor(second.id), 1);
      await store.flush();
      await store.saveSelectedProject();
      expect(repository.savedIds, [first.id]);
    },
  );

  test(
    'existing matrix and randomization save calls detect map mutations',
    () async {
      final project = await store.createProject();
      project.matrixState['range_0'] = '1.25';
      await store.saveSelectedProject();
      project.randomizeOrder = true;
      project.randomizeSequence = [1, 0];
      await store.saveSelectedProject();
      final saved = await repository.watchProject(project.id).first;
      expect(saved!.project.matrixState, {'range_0': '1.25'});
      expect(saved.project.randomizeSequence, [1, 0]);
      expect(saved.revision, 3);
    },
  );

  test(
    'clean remote updates arrive without producing a save feedback loop',
    () async {
      final project = await store.createProject();
      final remote = await repository.watchProject(project.id).first;
      remote!.project.formModel.setProjectTitle('Changed elsewhere');
      await repository.saveProject(remote.project, expectedRevision: 1);
      await _events();
      expect(store.selectedProject!.displayName, 'Changed elsewhere');
      expect(store.revisionFor(project.id), 2);
      expect(store.hasUnsavedChanges, isFalse);
      final writes = repository.savedIds.length;
      await store.flush();
      expect(repository.savedIds.length, writes);
    },
  );

  test(
    'dirty drafts survive remote updates and stale writes expose conflict',
    () async {
      final project = await store.createProject();
      final remote = await repository.watchProject(project.id).first;
      project.formModel.setProjectTitle('Local draft');
      remote!.project.formModel.setProjectTitle('Other device');
      await repository.saveProject(remote.project, expectedRevision: 1);
      await _events();
      expect(store.selectedProject, same(project));
      expect(store.selectedProject!.displayName, 'Local draft');
      await expectLater(store.flush(), throwsA(isA<ProjectConflict>()));
      expect(store.revisionFor(project.id), 1);
      expect(store.saveStateFor(project.id), ProjectSaveState.conflict);
      expect(store.hasUnsavedChanges, isTrue);
      expect(
        (await repository.watchProject(project.id).first)!.project.displayName,
        'Other device',
      );
    },
  );

  test(
    'edits made during a save remain dirty and use the acknowledged revision',
    () async {
      final project = await store.createProject();
      project.formModel.setProjectTitle('Submitted');
      final barrier = Completer<void>();
      repository.saveBarrier = barrier.future;
      final saving = store.saveSelectedProject();
      await _events();
      expect(store.saveStateFor(project.id), ProjectSaveState.saving);
      project.formModel.setProjectTitle('Newer draft');
      barrier.complete();
      await saving;
      expect(store.saveStateFor(project.id), ProjectSaveState.dirty);
      expect(store.selectedProject!.displayName, 'Newer draft');
      await store.flush();
      expect(store.revisionFor(project.id), 3);
      expect(store.saveStateFor(project.id), ProjectSaveState.saved);
      expect(
        (await repository.watchProject(project.id).first)!.project.displayName,
        'Newer draft',
      );
    },
  );

  test(
    'save failure retains the draft and the queue permits explicit retry',
    () async {
      final project = await store.createProject();
      project.formModel.setProjectTitle('Do not lose me');
      repository.saveFailure = StateError('offline');
      await expectLater(store.flush(), throwsStateError);
      expect(store.selectedProject!.displayName, 'Do not lose me');
      expect(store.saveStateFor(project.id), ProjectSaveState.error);
      repository.saveFailure = null;
      await store.flush();
      expect(store.saveStateFor(project.id), ProjectSaveState.saved);
    },
  );

  test(
    'failed deletion preserves local data; successful deletion reaches repository',
    () async {
      final project = await store.createProject();
      repository.deleteFailure = StateError('delete failed');
      await expectLater(store.deleteProject(project.id), throwsStateError);
      expect(store.selectedProject!.id, project.id);
      repository.deleteFailure = null;
      expect(await store.deleteProject(project.id), isTrue);
      expect(store.projects, isEmpty);
      expect(store.selectedProject, isNull);
      expect(repository.deletedIds, [project.id]);
    },
  );

  test(
    'selected remote deletion removes clean data but preserves a dirty draft',
    () async {
      final clean = await store.createProject();
      await repository.deleteProject(clean.id, expectedRevision: 1);
      await _events();
      expect(store.selectedProject, isNull);
      final dirty = await store.createProject();
      dirty.formModel.setProjectTitle('Unsaved work');
      await repository.deleteProject(dirty.id, expectedRevision: 1);
      await _events();
      expect(store.selectedProject, same(dirty));
      expect(store.saveStateFor(dirty.id), ProjectSaveState.conflict);
      await expectLater(store.flush(), throwsA(isA<ProjectConflict>()));
    },
  );

  test('loading errors retain data and re-subscription can recover', () async {
    final project = await store.createProject();
    repository.emitError(StateError('load failed'));
    await _events();
    expect(store.loadError, isStateError);
    expect(store.projects.single.id, project.id);
    await store.load();
    expect(store.loadError, isNull);
    expect(store.projects.single.id, project.id);
  });

  test('leaving the latest-25 query is not treated as deletion', () async {
    final original = await store.createProject();
    for (var i = 0; i < 26; i++) {
      final now = DateTime.now().toUtc();
      await repository.saveProject(
        SavedProject(
          id: repository.newProjectId(),
          createdAt: now,
          updatedAt: now,
          formModel: ProjectFormModel(),
        ),
        expectedRevision: 0,
      );
    }
    await _events();
    expect(store.projects.any((project) => project.id == original.id), isTrue);
    expect(store.selectedProject!.id, original.id);
  });

  test('separate repositories keep account data isolated', () async {
    final first = await store.createProject();
    final otherRepository = FakeProjectRepository();
    final other = ProjectStore(repository: otherRepository);
    await other.load();
    expect(other.projects, isEmpty);
    await other.createProject();
    expect(store.selectedProject, same(first));
    other.dispose();
    await otherRepository.dispose();
  });

  test(
    'dispose detaches listeners and does not persist later model changes',
    () async {
      final project = await store.createProject();
      final extra = ProjectStore(repository: repository);
      await extra.load();
      extra.dispose();
      var notifications = 0;
      store.addListener(() => notifications++);
      await store.selectProject(project.id);
      final remote = await repository.watchProject(project.id).first;
      remote!.project.formModel.setProjectTitle('Remote');
      await repository.saveProject(remote.project, expectedRevision: 1);
      await _events();
      expect(notifications, greaterThan(0));
      expect(extra.projects.single.displayName, 'Untitled Project');
    },
  );
  test(
    'remote deletion never switches the editor to a different project',
    () async {
      await store.createProject();
      final selected = await store.createProject();
      await repository.deleteProject(selected.id, expectedRevision: 1);
      await _events();
      expect(store.selectedProject, isNull);
      expect(store.projects.length, 1);
      final now = DateTime.now().toUtc();
      await repository.saveProject(
        SavedProject(
          id: repository.newProjectId(),
          createdAt: now,
          updatedAt: now,
          formModel: ProjectFormModel(),
        ),
        expectedRevision: 0,
      );
      await _events();
      expect(store.selectedProject, isNull);
    },
  );
}

Future<void> _events() => Future<void>.delayed(Duration.zero);

class _InitiallyFailingRepository extends FakeProjectRepository {
  bool fail = true;

  @override
  Stream<List<CloudProject>> watchProjects() => fail
      ? Stream.error(StateError('initial read failed'))
      : super.watchProjects();
}
