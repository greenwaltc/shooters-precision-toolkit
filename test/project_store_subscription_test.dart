import 'dart:async';
import 'dart:convert';

import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _PageRepository repository;
  late ProjectStore store;

  setUp(() {
    repository = _PageRepository();
    store = ProjectStore(
      repository: repository,
      saveDebounce: const Duration(hours: 1),
    );
  });

  tearDown(() async {
    store.dispose();
    await repository.dispose();
  });

  Future<void> loadPage(List<CloudProject> page) async {
    final loading = store.load();
    await _events();
    repository.emit(page);
    await loading;
  }

  test(
    'concurrent and repeated loads attach exactly one page listener',
    () async {
      final loads = List.generate(8, (_) => store.load());
      expect(loads.every((future) => identical(future, loads.first)), isTrue);
      await _events();
      expect(repository.watchCalls, 1);
      expect(repository.activeListeners, 1);
      repository.emit([_record('First version', 1)]);
      await Future.wait(loads);
      await store.load();
      expect(repository.watchCalls, 1);
      repository.emit([_record('Later snapshot', 2)]);
      await _events();
      expect(store.selectedProject!.displayName, 'Later snapshot');
      expect(store.revisionFor('remote'), 2);
      expect(repository.savedIds, isEmpty);
    },
  );

  test(
    'retry cancels the failed listener without losing the editable draft',
    () async {
      await loadPage([_record('Original', 1)]);
      final original = store.selectedProject!;
      original.formModel.setProjectTitle('Local draft');
      final revision = store.revisionFor(original.id);
      final counter = store.editStateFor(original.id)!.editCounter;
      final failure = StateError('subscription failed');
      repository.fail(failure);
      await _events();
      expect(store.loadError, same(failure));
      expect(store.selectedProject, same(original));
      expect(store.loadState, WorkspaceLoadState.error);

      final retry = store.load();
      final repeated = store.load();
      expect(retry, same(repeated));
      await _events();
      expect(repository.watchCalls, 2);
      expect(repository.cancelledListeners, 1);
      expect(repository.activeListeners, 1);
      repository.emit([_record('Changed remotely', 2)]);
      await retry;
      expect(store.loadError, isNull);
      expect(store.selectedProject, same(original));
      expect(original.displayName, 'Local draft');
      expect(store.revisionFor(original.id), revision);
      expect(store.editStateFor(original.id)!.editCounter, counter);
      expect(store.canDiscardDraft(original.id), isTrue);
      expect(repository.savedIds, isEmpty);
    },
  );

  test(
    'an unexpected stream close finishes initial load as an error and permits retry',
    () async {
      final loading = store.load();
      await _events();
      await repository.closeCurrentPage();
      await loading;
      expect(store.isLoaded, isFalse);
      expect(store.loadError, isStateError);
      expect(store.loadState, WorkspaceLoadState.error);
      await loadPage([]);
      expect(repository.watchCalls, 2);
      expect(store.loadState, WorkspaceLoadState.empty);
    },
  );

  test(
    'a stream ending after data retains the projects and the original error',
    () async {
      await loadPage([_record('Keep this project', 1)]);
      final failure = StateError('permission denied');
      repository.fail(failure);
      await _events();
      await repository.closeCurrentPage();
      expect(store.loadError, same(failure));
      expect(store.projects.single.displayName, 'Keep this project');
      await loadPage([_record('Recovered', 2)]);
      expect(store.loadError, isNull);
      expect(store.projects.single.displayName, 'Recovered');
    },
  );

  test(
    'clean model replacement detaches old edits and tracks the new form once',
    () async {
      await loadPage([_record('First', 1)]);
      final oldModel = store.selectedProject!.formModel;
      repository.emit([_record('Replacement', 2)]);
      await _events();
      final accepted = store.selectedProject!;
      oldModel.setProjectTitle('Detached form');
      expect(accepted.displayName, 'Replacement');
      expect(store.hasUnsavedChanges, isFalse);
      final before = store.editStateFor(accepted.id)!.editCounter;
      accepted.formModel.setProjectTitle('A new local edit');
      expect(store.editStateFor(accepted.id)!.editCounter, before + 1);
      expect(store.hasUnsavedChanges, isTrue);
      expect(repository.savedIds, isEmpty);
    },
  );

  test(
    'metadata-only and older snapshots neither replace clean models nor write',
    () async {
      await loadPage([_record('Stable', 2)]);
      final project = store.selectedProject!;
      final metadataOnly = _copy(project)
        ..updatedAt = DateTime.utc(2026, 11, 2);
      repository.emit([CloudProject(metadataOnly, 2, false)]);
      repository.emit([_record('Stale payload', 1)]);
      repository.emit([_record('Pending local SDK payload', 3, pending: true)]);
      await _events();
      expect(store.selectedProject, same(project));
      expect(project.displayName, 'Stable');
      expect(project.updatedAt, metadataOnly.updatedAt);
      expect(store.revisionFor(project.id), 2);
      expect(store.hasUnsavedChanges, isFalse);
      await store.flush();
      expect(repository.savedIds, isEmpty);
    },
  );

  test(
    'page snapshots during a save preserve the submitted snapshot and newer edits',
    () async {
      await loadPage([]);
      final project = await store.createProject();
      project.formModel.setProjectTitle('Submitted');
      final barrier = Completer<void>();
      repository.saveBarrier = barrier.future;
      final saving = store.saveSelectedProject();
      await _events();
      final submitted = _copy(project);
      project.formModel.setProjectTitle('Typed while saving');
      repository.emit([CloudProject(submitted, 2, false)]);
      await _events();
      expect(store.selectedProject, same(project));
      expect(project.displayName, 'Typed while saving');
      expect(store.revisionFor(project.id), 1);
      expect(store.editStateFor(project.id)!.isSaving, isTrue);
      barrier.complete();
      await saving;
      expect(store.revisionFor(project.id), 2);
      expect(store.editStateFor(project.id)!.isDirty, isTrue);
      expect(
        (await repository.savedProject(project.id))!.project.displayName,
        'Submitted',
      );
      await store.flush();
      expect(
        (await repository.savedProject(project.id))!.project.displayName,
        'Typed while saving',
      );
      expect(store.revisionFor(project.id), 3);
    },
  );

  test(
    'synchronous subscription failures finish loading and allow retry',
    () async {
      repository.throwOnWatch = true;
      await store.load();
      expect(store.loadError, isStateError);
      expect(store.isLoaded, isFalse);
      repository.throwOnWatch = false;
      await loadPage([_record('Retried', 1)]);
      expect(store.loadError, isNull);
      expect(store.projects.single.displayName, 'Retried');
    },
  );

  test(
    'disposing before the first result completes load and detaches the listener',
    () async {
      final backend = _PageRepository();
      final workspace = ProjectStore(repository: backend);
      final loading = workspace.load();
      await _events();
      expect(backend.activeListeners, 1);
      workspace.dispose();
      await loading;
      await _events();
      expect(backend.activeListeners, 0);
      backend.emit([_record('After disposal', 1)]);
      await _events();
      expect(workspace.projects, isEmpty);
      await backend.dispose();
    },
  );
}

Future<void> _events() => Future<void>.delayed(Duration.zero);

SavedProject _copy(SavedProject project) => SavedProject.fromJson(
  jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
);

CloudProject _record(String title, int revision, {bool pending = false}) =>
    CloudProject(
      SavedProject(
        id: 'remote',
        createdAt: DateTime.utc(2026, 10, 31),
        updatedAt: DateTime.utc(2026, 10, 31, 0, revision),
        formModel: ProjectFormModel()..setProjectTitle(title),
      ),
      revision,
      pending,
    );

/// Page events are controlled separately from writes to test subscription timing.
class _PageRepository extends FakeProjectRepository {
  final _pages = <StreamController<List<CloudProject>>>[];
  int watchCalls = 0;
  int activeListeners = 0;
  int cancelledListeners = 0;
  bool throwOnWatch = false;

  @override
  Stream<List<CloudProject>> watchProjects() {
    watchCalls++;
    if (throwOnWatch) throw StateError('Cannot attach subscription');
    final page = StreamController<List<CloudProject>>.broadcast(sync: true);
    _pages.add(page);
    return Stream<List<CloudProject>>.multi((listener) {
      activeListeners++;
      final subscription = page.stream.listen(
        listener.addSync,
        onError: listener.addErrorSync,
        onDone: listener.closeSync,
      );
      listener.onCancel = () async {
        activeListeners--;
        cancelledListeners++;
        await subscription.cancel();
      };
    });
  }

  @override
  Stream<CloudProject?> watchProject(String id) => const Stream.empty();

  void emit(List<CloudProject> page) => _pages.last.add(page);
  void fail(Object error) => _pages.last.addError(error);
  Future<void> closeCurrentPage() => _pages.last.close();
  Future<CloudProject?> savedProject(String id) => super.watchProject(id).first;

  @override
  Future<void> dispose() async {
    for (final page in _pages) {
      await page.close();
    }
    await super.dispose();
  }
}
