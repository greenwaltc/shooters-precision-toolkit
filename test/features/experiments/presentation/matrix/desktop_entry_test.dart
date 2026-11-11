import 'dart:async';

import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/services/matrix_grid_data_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/matrix_test_fixture.dart';

void main() {
  testWidgets('Enter keeps each desktop editor live across an autosave', (
    tester,
  ) async {
    final repository = FakeProjectRepository();
    final (store, manager) = await pumpMatrixFixture(
      tester,
      repository: repository,
      saveDebounce: const Duration(seconds: 2),
    );
    final acknowledgement = Completer<void>();
    repository.saveBarrier = acknowledgement.future;
    manager.setEditing(true);
    await tester.pumpAndSettle();

    for (var row = 0; row < 8; row++) {
      expect(manager.currentRowIdx, row);
      final field = find.byType(TextField);
      await tester.enterText(field, '${row + 10}.5');
      await tester.pump();
      expect(
        store
            .selectedProject!
            .matrixState[MatrixGridDataBuilder.storageKeyForRow(
          manager.rows[row],
        )],
        '${row + 10}.5',
        reason: 'The active cell must sync before Enter or a save returns',
      );
      if (row == 3) {
        await tester.pump(const Duration(seconds: 2));
      }
      if (row == 4) {
        acknowledgement.complete();
        await tester.pump();
        await tester.pump();
        expect(
          tester.state<PlutoGridState>(find.byType(PlutoGrid)).stateManager,
          same(manager),
        );
        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }
    await store.saveSelectedProject();
    expect(
      repository.remoteProject(store.selectedProject!.id)!.project.matrixState,
      containsPair(
        MatrixGridDataBuilder.storageKeyForRow(manager.rows[7]),
        '17.5',
      ),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
