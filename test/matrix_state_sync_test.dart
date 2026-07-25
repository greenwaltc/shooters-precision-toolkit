import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_matrix/services/matrix_grid_data_builder.dart';

void main() {
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
