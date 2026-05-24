import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shooters_precision_test_kit/main.dart';
import 'package:shooters_precision_test_kit/model/project_store.dart';
import 'package:shooters_precision_test_kit/storage/project_storage.dart';

void main() {
  testWidgets('project home renders empty state and create action', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text("Shooter's Precision Test Kit"), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('Create a New Project'), findsOneWidget);
  });

  testWidgets('creating a project opens ANOMR form defaults', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    expect(find.text('New ANOMR Project'), findsOneWidget);
    expect(find.text('Project Name'), findsOneWidget);
    expect(
      find.text('Choose the Structure of Your Experiment'),
      findsOneWidget,
    );
    expect(
      find.text('Test How One Factor (two states) Influences A'),
      findsOneWidget,
    );
    expect(find.text('Impute missing data with the grand mean'), findsOneWidget);
    expect(
      find.text('8 total ranges in 4 replicates of 2 ranges each'),
      findsOneWidget,
    );
  });

  testWidgets('sample size section follows selected risk level', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await tester.ensureVisible(find.text('5%').first);
    await tester.tap(find.text('5%').first);
    await tester.pumpAndSettle();

    expect(find.text('±52%'), findsOneWidget);
    expect(find.text('±40%'), findsOneWidget);
    expect(find.text('±20%'), findsOneWidget);
    expect(find.text('±45%'), findsNothing);
    expect(find.textContaining('+-'), findsNothing);
  });

  testWidgets('ANOMR project form validates required text fields', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Project name is required.'), findsOneWidget);
    expect(find.text('Factor name is required.'), findsOneWidget);
    expect(find.text('Factor state is required.'), findsNWidgets(2));
  });

  testWidgets('ANOMR project form updates dynamic factor and sample sections', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await tester.tap(find.text('Test How Three Factors Influence A'));
    await tester.pumpAndSettle();

    expect(find.text('Factor 3'), findsOneWidget);
    expect(
      find.text('16 total ranges in 2 replicates of 8 ranges each'),
      findsOneWidget,
    );
  });

  testWidgets('form submits to matrix and setup round trip preserves state', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _createProject(tester);

    await _enterSimpleProject(tester);

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Range Test'), findsWidgets);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(titleField.controller?.text, 'Range Test');
  });

  testWidgets('project state persists to storage and reloads on home page', (
    WidgetTester tester,
  ) async {
    final storage = InMemoryProjectStorage();
    final store = ProjectStore(storage: storage);
    await store.load();

    await tester.pumpWidget(MyApp(projectStore: store));
    await tester.pumpAndSettle();
    await _createProject(tester);
    await _enterSimpleProject(tester);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    final reloadedStore = ProjectStore(storage: storage);
    await reloadedStore.load();

    expect(reloadedStore.projects.single.formModel.projectTitle, 'Range Test');
    expect(find.text('Range Test'), findsOneWidget);
  });

  testWidgets('project deletion requires confirmation and removes storage', (
    WidgetTester tester,
  ) async {
    final storage = InMemoryProjectStorage();
    final store = ProjectStore(storage: storage);
    await store.load();

    await tester.pumpWidget(MyApp(projectStore: store));
    await tester.pumpAndSettle();
    await _createProject(tester);
    await _enterSimpleProject(tester);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete project?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Range Test'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final reloadedStore = ProjectStore(storage: storage);
    await reloadedStore.load();

    expect(find.text('No projects yet'), findsOneWidget);
    expect(reloadedStore.projects, isEmpty);
  });
}

Future<ProjectStore> _pumpApp(WidgetTester tester) async {
  final store = ProjectStore(storage: InMemoryProjectStorage());
  await store.load();
  await tester.pumpWidget(MyApp(projectStore: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> _createProject(WidgetTester tester) async {
  await tester.tap(find.text('Create a New Project'));
  await tester.pumpAndSettle();
}

Future<void> _enterSimpleProject(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Range Test');
  await tester.enterText(fields.at(1), 'Primer');
  await tester.enterText(fields.at(2), 'Standard');
  await tester.enterText(fields.at(3), 'Magnum');
  await tester.pumpAndSettle();
}
