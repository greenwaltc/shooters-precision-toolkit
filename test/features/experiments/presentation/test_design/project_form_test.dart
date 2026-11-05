import 'dart:math';

import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/shared/ui/product_configuration.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/test_configuration.dart';

void main() {
  testWidgets('project home renders empty state and create action', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    final brand = ProjectConfiguration.defaults.brand;
    final uiCopy = ProjectConfiguration.defaults.uiCopy;

    expect(find.text(brand.tagline), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text(uiCopy.createProjectLabel), findsOneWidget);
  });

  testWidgets('creating a project opens ANOMR form defaults', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    expect(find.text('Untitled Project'), findsOneWidget);
    expect(find.text('Project Name'), findsOneWidget);
    expect(
      find.text('Choose the Structure of Your Experiment'),
      findsOneWidget,
    );
    expect(
      find.text('Test how one factor (two states) influences precision'),
      findsOneWidget,
    );
    expect(find.text('8 total group sizes in 2 groups of 4'), findsOneWidget);
  });

  testWidgets('home page hides theme toggle when feature flag is off', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);
  });

  testWidgets('sample size section follows selected risk level', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await tester.ensureVisible(find.text('5%').first);
    await tester.tap(find.text('5%').first);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.textContaining('±52%'), findsOneWidget);
    expect(find.textContaining('±40%'), findsOneWidget);
    expect(find.textContaining('±20%'), findsOneWidget);
    expect(find.textContaining('±45%'), findsNothing);
    expect(find.textContaining('+-'), findsNothing);
  });

  testWidgets('ANOMR project form validates required text fields', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.text('Project name is required.'), findsOneWidget);
    expect(find.text('Factor name is required.'), findsOneWidget);
    expect(find.text('Factor state is required.'), findsNWidgets(2));
  });

  testWidgets('ANOMR project form updates dynamic factor and sample sections', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    final threeFactorOption = find.text(
      'Test how three factors influence precision',
    );
    await tester.ensureVisible(threeFactorOption);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.tap(threeFactorOption);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.text('Factor 3'), findsOneWidget);
    expect(find.text('16 total group sizes'), findsOneWidget);
  });

  testWidgets('form submits to matrix and setup round trip preserves state', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await _enterSimpleProject(tester);

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.text('Range Test'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    final titleField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(titleField.controller?.text, 'Range Test');

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('project state persists to storage and reloads on home page', (
    WidgetTester tester,
  ) async {
    final storage = FakeProjectRepository();
    final store = ProjectStore(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      draftStorage: InMemoryProjectDraftStorage(),
      repository: storage,
      saveDebounce: Duration.zero,
    );
    addTearDown(store.dispose);
    await store.load();

    await pumpConfiguredWidget(
      tester,
      MyApp(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        config: testConfig(),
        random: Random(4729),
        projectStore: store,
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await _createProject(tester);
    await _enterSimpleProject(tester);

    if (find.byTooltip('Projects').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await tester.tap(find.text('Projects'));
    } else {
      await tester.tap(find.byTooltip('Projects'));
    }
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    final reloadedStore = ProjectStore(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      draftStorage: InMemoryProjectDraftStorage(),
      repository: storage,
      saveDebounce: Duration.zero,
    );
    addTearDown(reloadedStore.dispose);
    await reloadedStore.load();

    expect(reloadedStore.projects.single.formModel.projectTitle, 'Range Test');
    expect(find.text('Range Test'), findsOneWidget);
  });

  testWidgets('project deletion requires confirmation and removes storage', (
    WidgetTester tester,
  ) async {
    final storage = FakeProjectRepository();
    final store = ProjectStore(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      draftStorage: InMemoryProjectDraftStorage(),
      repository: storage,
      saveDebounce: Duration.zero,
    );
    addTearDown(store.dispose);
    await store.load();

    await pumpConfiguredWidget(
      tester,
      MyApp(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        config: testConfig(),
        random: Random(4729),
        projectStore: store,
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await _createProject(tester);
    await _enterSimpleProject(tester);

    if (find.byTooltip('Projects').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await tester.tap(find.text('Projects'));
    } else {
      await tester.tap(find.byTooltip('Projects'));
    }
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.text('Delete project?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(find.text('Range Test'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    final reloadedStore = ProjectStore(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      draftStorage: InMemoryProjectDraftStorage(),
      repository: storage,
      saveDebounce: Duration.zero,
    );
    addTearDown(reloadedStore.dispose);
    await reloadedStore.load();

    expect(find.text('No projects yet'), findsOneWidget);
    expect(reloadedStore.projects, isEmpty);
  });
}

Future<ProjectStore> _pumpApp(WidgetTester tester) async {
  final store = ProjectStore(
    clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
    draftStorage: InMemoryProjectDraftStorage(),
    repository: FakeProjectRepository(),
    saveDebounce: Duration.zero,
  );
  addTearDown(store.dispose);
  await store.load();
  await pumpConfiguredWidget(
    tester,
    MyApp(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      config: testConfig(),
      random: Random(4729),
      projectStore: store,
    ),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  return store;
}

Future<void> _createProject(WidgetTester tester) async {
  await tester.tap(
    find.text(ProjectConfiguration.defaults.uiCopy.createProjectLabel),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

Future<void> _enterSimpleProject(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Range Test');
  await tester.enterText(fields.at(1), 'Primer');
  await tester.enterText(fields.at(2), 'Standard');
  await tester.enterText(fields.at(3), 'Magnum');
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}
