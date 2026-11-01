import 'dart:async';

import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/project_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repository repository;
  late ProjectStore store;
  setUp(() {
    repository = _Repository();
    store = ProjectStore(
      repository: repository,
      saveDebounce: const Duration(hours: 1),
    );
  });
  tearDown(() async {
    store.dispose();
    await repository.dispose();
  });
  Future<void> load() async {
    final loading = store.load();
    await _events();
    repository.pages.add(_page(100, 25));
    await loading;
  }

  test(
    'pages advance by fetched cursor, deduplicate, and stop at the end',
    () async {
      await load();
      final first = store.loadOlderProjects();
      expect(repository.cursors.single.project.id, 'p76');
      expect(store.isLoadingOlder, isTrue);
      await store.loadOlderProjects();
      expect(repository.requests, hasLength(1));
      repository.requests[0].complete(
        _page(76, 25),
      ); // Includes a boundary duplicate.
      await first;
      expect(store.projects, hasLength(49));
      final second = store.loadOlderProjects();
      expect(repository.cursors.last.project.id, 'p52');
      repository.requests[1].complete(_page(51, 3));
      await second;
      expect(store.projects, hasLength(52));
      expect(store.hasMoreProjects, isFalse);
    },
  );

  test('errors preserve loaded models and retry the same cursor', () async {
    await load();
    final loading = store.loadOlderProjects();
    repository.requests.single.completeError(StateError('offline'));
    await loading;
    expect(store.projects, hasLength(25));
    expect(store.loadError, isNull);
    expect(store.olderProjectsError, isStateError);
    final retry = store.loadOlderProjects();
    expect(repository.cursors.last, same(repository.cursors.first));
    repository.requests.last.complete([]);
    await retry;
    expect(store.olderProjectsError, isNull);
  });

  test(
    'reordering invalidates in-flight pages without dropping viewed projects',
    () async {
      await load();
      final loading = store.loadOlderProjects();
      repository.pages.add(_page(101, 25));
      repository.requests.single.complete(_page(75, 25));
      await loading;
      expect(store.projects.map((p) => p.id), contains('p76'));
      expect(store.projects.map((p) => p.id), isNot(contains('p75')));
      final retry = store.loadOlderProjects();
      expect(repository.cursors.last.project.id, 'p77');
      repository.requests.last.complete(_page(76, 2));
      await retry;
      expect(store.projects.map((p) => p.id), contains('p75'));
    },
  );

  test('metadata-only events do not restart an advanced cursor', () async {
    await load();
    var loading = store.loadOlderProjects();
    repository.requests.last.complete(_page(75, 25));
    await loading;
    repository.pages.add(_page(100, 25));
    loading = store.loadOlderProjects();
    expect(repository.cursors.last.project.id, 'p51');
    repository.requests.last.complete([]);
    await loading;
  });

  test(
    'selected older document updates and old listeners are cancelled',
    () async {
      await load();
      final loading = store.loadOlderProjects();
      repository.requests.last.complete(_page(75, 2));
      await loading;
      await store.selectProject('p75');
      await _events();
      expect(repository.activeSelected, {'p75'});
      repository.selected['p75']!.add(
        _record(75, revision: 2, title: 'Remote edit'),
      );
      expect(store.selectedProject!.displayName, 'Remote edit');
      await store.selectProject('p74');
      await _events();
      expect(repository.activeSelected, {'p74'});
      repository.selected['p75']!.add(
        _record(75, revision: 3, title: 'Old listener'),
      );
      expect(
        store.projects.firstWhere((p) => p.id == 'p75').displayName,
        'Remote edit',
      );
      repository.selected['p74']!.add(null);
      expect(store.selectedProject, isNull);
      expect(store.projects.map((p) => p.id), isNot(contains('p74')));
      await _events();
      expect(repository.activeSelected, isEmpty);
    },
  );

  test(
    'selected-project reordering restarts paging from the live boundary',
    () async {
      await load();
      var loading = store.loadOlderProjects();
      repository.requests.last.complete(_page(75, 2));
      await loading;
      expect(store.hasMoreProjects, isFalse);
      await store.selectProject('p75');
      final moved = _record(75, revision: 2);
      moved.project.updatedAt = DateTime.utc(2027);
      repository.selected['p75']!.add(moved);
      expect(store.hasMoreProjects, isTrue);
      loading = store.loadOlderProjects();
      expect(repository.cursors.last.project.id, 'p76');
      repository.requests.last.complete([]);
      await loading;
    },
  );

  test('a confirmed deletion invalidates pages already in flight', () async {
    await load();
    final loading = store.loadOlderProjects();
    repository.selected['p100']!.add(null);
    repository.requests.last.complete([_record(100)]);
    await loading;
    expect(store.projects.map((p) => p.id), isNot(contains('p100')));
  });

  test('older page responses preserve dirty drafts and revisions', () async {
    await load();
    final project = store.selectedProject!;
    project.formModel.setProjectTitle('Unsaved draft');
    final loading = store.loadOlderProjects();
    repository.requests.single.complete([
      _record(100, revision: 2, title: 'Remote version'),
    ]);
    await loading;
    expect(store.selectedProject, same(project));
    expect(project.displayName, 'Unsaved draft');
    expect(store.revisionFor(project.id), 1);
    expect(store.saveStateFor(project.id), ProjectSaveState.conflict);
  });

  testWidgets('home button disables while loading and shows retry on failure', (
    tester,
  ) async {
    final loading = store.load();
    await tester.pump();
    repository.pages.add(_page(100, 25));
    await loading;
    await tester.pumpWidget(MyApp(projectStore: store));
    await tester.pumpAndSettle();
    var button = find.widgetWithText(OutlinedButton, 'Load older projects');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Loading older projects…'),
          )
          .onPressed,
      isNull,
    );
    repository.requests.single.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Retry loading older projects'), findsOneWidget);
    expect(
      find.text('Unable to load older projects. Please try again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'disposal ignores a pending response and releases selected listener',
    () async {
      final backend = _Repository();
      final workspace = ProjectStore(repository: backend);
      final first = workspace.load();
      await _events();
      backend.pages.add(_page(100, 25));
      await first;
      final loading = workspace.loadOlderProjects();
      workspace.dispose();
      backend.requests.single.complete(_page(75, 25));
      await loading;
      expect(workspace.projects, hasLength(25));
      await _events();
      expect(backend.activeSelected, isEmpty);
      await backend.dispose();
    },
  );
}

Future<void> _events() => Future<void>.delayed(Duration.zero);
List<CloudProject> _page(int newest, int count) => [
  for (var i = 0; i < count; i++) _record(newest - i),
];
CloudProject _record(int index, {int revision = 1, String? title}) =>
    CloudProject(
      SavedProject(
        id: 'p$index',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 1, 0, index),
        formModel: ProjectFormModel()
          ..setProjectTitle(title ?? 'Project $index'),
      ),
      revision,
      false,
    );

class _Repository extends FakeProjectRepository {
  final pages = StreamController<List<CloudProject>>.broadcast(sync: true);
  final requests = <Completer<List<CloudProject>>>[];
  final cursors = <CloudProject>[];
  final selected = <String, StreamController<CloudProject?>>{};
  final activeSelected = <String>{};

  @override
  Stream<List<CloudProject>> watchProjects() => pages.stream;
  @override
  Future<List<CloudProject>> fetchOlderProjects({required CloudProject after}) {
    cursors.add(after);
    final request = Completer<List<CloudProject>>();
    requests.add(request);
    return request.future;
  }

  @override
  Stream<CloudProject?> watchProject(String id) {
    return (selected[id] ??= StreamController<CloudProject?>.broadcast(
      sync: true,
      onListen: () => activeSelected.add(id),
      onCancel: () => activeSelected.remove(id),
    )).stream;
  }

  @override
  Future<void> dispose() async {
    await pages.close();
    for (final controller in selected.values) {
      await controller.close();
    }
    await super.dispose();
  }
}
