import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'fake_project_repository.dart';

Future<(ProjectStore, PlutoGridStateManager)> pumpMatrixFixture(
  WidgetTester tester, {
  Duration saveDebounce = Duration.zero,
}) async {
  rootBundle.clear();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final store = ProjectStore(
    repository: FakeProjectRepository(),
    saveDebounce: saveDebounce,
  );
  addTearDown(store.dispose);
  await store.load();
  final project = await store.createProject();
  final model = project.formModel;
  model.setProjectTitle('Clipboard fixture');
  model.setExperimentStructure(
    ExperimentStructure.values.firstWhere((s) => s.factorCount == 2),
  );
  for (var i = 0; i < 2; i++) {
    model.setFactorDefinition(
      index: i,
      name: 'Factor $i',
      firstState: 'Low $i',
      secondState: 'High $i',
    );
  }
  expect(await store.completeProjectSetup(), isTrue);
  for (var i = 0; i < model.sampleSizeOption.totalSamples; i++) {
    project.matrixState['range_$i'] = '${i + 1}';
  }
  await tester.pumpWidget(MyApp(projectStore: store));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Clipboard fixture'));
  await tester.pumpAndSettle();
  final manager = tester
      .state<PlutoGridState>(find.byType(PlutoGrid))
      .stateManager;
  manager.setCurrentCell(manager.rows.first.cells['range'], 0);
  manager.setKeepFocus(true);
  manager.gridFocusNode.requestFocus();
  await tester.pumpAndSettle();
  return (store, manager);
}

Finder matrixCell(int row, String field) =>
    find.byKey(ValueKey('matrix-cell-$row-$field'));
