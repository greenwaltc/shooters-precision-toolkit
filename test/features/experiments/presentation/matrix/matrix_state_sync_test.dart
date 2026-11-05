import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/data_matrix_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/services/matrix_grid_data_builder.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/saved_project.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../support/matrix_test_fixture.dart';

void main() {
  test('factor states change fastest at the left within each replicate', () {
    final form = ProjectFormModel(
      experimentStructure: ExperimentStructure.threeFactors,
      factorDefinitions: const [
        FactorDefinition(firstState: 'A0', secondState: 'A1'),
        FactorDefinition(firstState: 'B0', secondState: 'B1'),
        FactorDefinition(firstState: 'C0', secondState: 'C1'),
      ],
    );
    final project = SavedProject(
      id: 'three-factor',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      formModel: form,
      matrixState: {'range_4': '2.5', 'range_1': '7.5'},
    );

    final rows = MatrixGridDataBuilder.build(
      formModel: form,
      project: project,
    ).rows;

    expect(
      rows
          .take(9)
          .map(
            (row) => [
              for (final field in [
                'row',
                'group',
                'factor_0',
                'factor_1',
                'factor_2',
              ])
                row.cells[field]!.value,
            ],
          ),
      [
        [1, 1, 'A0', 'B0', 'C0'],
        [2, 1, 'A1', 'B0', 'C0'],
        [3, 1, 'A0', 'B1', 'C0'],
        [4, 1, 'A1', 'B1', 'C0'],
        [5, 1, 'A0', 'B0', 'C1'],
        [6, 1, 'A1', 'B0', 'C1'],
        [7, 1, 'A0', 'B1', 'C1'],
        [8, 1, 'A1', 'B1', 'C1'],
        [9, 2, 'A0', 'B0', 'C0'],
      ],
    );
    expect(rows[1].cells['range']!.value, '2.5');
    expect(rows[4].cells['range']!.value, '7.5');
  });

  testWidgets(
    'reopening a randomized matrix and toggling off restores run order',
    (tester) async {
      final (store, manager) = await pumpMatrixFixture(tester);
      final randomize = find.byType(Switch);
      List<int> storageOrder(PlutoGridStateManager grid) => [
        for (final row in grid.rows) row.cells['storage']!.value as int,
      ];
      final original = storageOrder(manager);
      expect(original.take(4), [0, 2, 1, 3]);

      await tester.tap(randomize);
      await tester.pumpAndSettle();
      final randomized = storageOrder(manager);
      expect(randomized, isNot(original));
      expect(store.selectedProject!.randomizeSequence, randomized);

      Navigator.of(tester.element(find.byType(AnomrMatrix))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clipboard fixture'));
      await tester.pumpAndSettle();
      final reopened = tester
          .state<PlutoGridState>(find.byType(PlutoGrid))
          .stateManager;
      expect(storageOrder(reopened), randomized);

      await tester.tap(randomize);
      await tester.pumpAndSettle();
      expect(storageOrder(reopened), original);
      expect(reopened.rows[1].cells['range']!.value, '3');
      expect(store.selectedProject!.randomizeSequence, isNull);
    },
  );

  test('syncMatrixStateFromRows copies cell values the store was missing', () {
    final project = SavedProject(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      formModel: ProjectFormModel(),
      // Simulate the bug: only the last cell made it into persistence.
      matrixState: {'range_1': '2'},
    );

    final rows = <PlutoRow>[
      PlutoRow(
        cells: {
          'storage': PlutoCell(value: 0),
          'range': PlutoCell(value: '1.5'),
        },
      ),
      PlutoRow(
        cells: {
          'storage': PlutoCell(value: 1),
          'range': PlutoCell(value: '2'),
        },
      ),
      PlutoRow(
        cells: {
          'storage': PlutoCell(value: 2),
          'range': PlutoCell(value: '3'),
        },
      ),
    ];

    final changed = MatrixGridDataBuilder.syncMatrixStateFromRows(
      project: project,
      rows: rows,
    );

    expect(changed, isTrue);
    expect(project.matrixState['range_0'], '1.5');
    expect(project.matrixState['range_1'], '2');
    expect(project.matrixState['range_2'], '3');
  });
}
