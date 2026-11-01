import 'dart:async';

import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/storage/project_repository.dart';
import 'package:bramwells_precision_test_kit/widgets/project_home_page.dart';
import 'package:bramwells_precision_test_kit/widgets/project_save_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_project_repository.dart';

void main() {
  testWidgets(
    'save feedback follows dirty, saving, error, retry and saved states',
    (tester) async {
      final backend = FakeProjectRepository();
      final store = ProjectStore(
        repository: backend,
        saveDebounce: const Duration(days: 1),
      );
      addTearDown(backend.dispose);
      await store.load();
      final project = await store.createProject();
      await _pumpStatus(tester, store);
      expect(find.text('Saved'), findsOneWidget);
      project.formModel.setProjectTitle('Unsaved');
      await tester.pump();
      expect(find.text('Unsaved changes'), findsOneWidget);
      final barrier = Completer<void>();
      backend.saveBarrier = barrier.future;
      final saving = store.saveSelectedProject();
      await tester.pump();
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      barrier.complete();
      await saving;
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      project.formModel.setProjectTitle('Needs retry');
      backend.saveFailure = StateError('offline');
      await expectLater(store.saveSelectedProject(), throwsStateError);
      await tester.pump();
      expect(
        find.text('Unable to save. Your changes are kept.'),
        findsOneWidget,
      );
      backend.saveFailure = null;
      await tester.tap(find.text('Retry save'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      expect(store.selectedProject!.displayName, 'Needs retry');
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets(
    'Save uploads only the selection without waiting for the debounce',
    (tester) async {
      late FakeProjectRepository backend;
      late ProjectStore store;
      await tester.runAsync(() async {
        backend = FakeProjectRepository();
        store = ProjectStore(
          repository: backend,
          saveDebounce: const Duration(days: 1),
        );
        await store.load();
        final first = await store.createProject();
        final second = await store.createProject();
        await store.selectProject(first.id);
        first.formModel.setProjectTitle('Save this project');
        second.formModel.setProjectTitle('Keep the other draft');
        backend.savedIds.clear();
      });
      addTearDown(backend.dispose);
      await _pumpStatus(tester, store);
      await tester.tap(find.text('Save'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(backend.savedIds, [store.selectedProject!.id]);
      expect(find.text('Saved'), findsOneWidget);
      expect(store.hasUnsavedChanges, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets(
    'conflict choices preserve the draft until discard is confirmed',
    (tester) async {
      late FakeProjectRepository backend;
      late ProjectStore store;
      await tester.runAsync(() async {
        backend = FakeProjectRepository();
        store = ProjectStore(
          repository: backend,
          saveDebounce: const Duration(days: 1),
        );
        await store.load();
        final project = await store.createProject();
        final remote = (await backend.watchProject(project.id).first)!;
        project.formModel.setProjectTitle('Local');
        remote.project.formModel.setProjectTitle('Cloud');
        await backend.saveProject(remote.project, expectedRevision: 1);
        await expectLater(
          store.saveSelectedProject(),
          throwsA(isA<ProjectConflict>()),
        );
      });
      addTearDown(backend.dispose);
      await tester.pumpWidget(MyApp(projectStore: store));
      await tester.pumpAndSettle();
      expect(find.text('Save conflict. Your draft is kept.'), findsOneWidget);
      await tester.tap(find.text('Review conflict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(store.selectedProject!.displayName, 'Local');
      expect(store.hasUnsavedChanges, isTrue);
      await tester.tap(find.text('Review conflict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard draft and reload'));
      await tester.pumpAndSettle();
      expect(store.selectedProject!.displayName, 'Cloud');
      expect(find.text('Saved'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets('a query failure is shown even after an empty workspace loaded', (
    tester,
  ) async {
    final backend = FakeProjectRepository();
    final store = ProjectStore(repository: backend);
    addTearDown(backend.dispose);
    await store.load();
    await tester.pumpWidget(MyApp(projectStore: store));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectHomePage), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
    backend.emitError(StateError('query failed'));
    await tester.pumpAndSettle();
    expect(store.loadState, WorkspaceLoadState.error);
    expect(find.text('Unable to load your projects.'), findsOneWidget);
    expect(find.text('No projects yet'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No projects yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}

Future<void> _pumpStatus(WidgetTester tester, ProjectStore store) =>
    tester.pumpWidget(
      ChangeNotifierProvider<ProjectStore>.value(
        value: store,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ProjectSaveStatus()),
        ),
      ),
    );
