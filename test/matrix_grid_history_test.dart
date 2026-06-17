import 'package:flutter_test/flutter_test.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_matrix/services/matrix_grid_history.dart';

void main() {
  group('MatrixGridHistoryController', () {
    test('records and undoes a single change', () {
      final history = MatrixGridHistoryController();
      history.record(
        const MatrixRangeChange(
          rowIdx: 2,
          previousValue: null,
          newValue: '0.7',
        ),
      );

      final entry = history.popUndo();
      expect(entry, isNotNull);
      expect(entry!.changes, hasLength(1));
      expect(entry.changes.first.previousValue, isNull);
      expect(entry.changes.first.newValue, '0.7');
    });

    test('groups batched changes into one undo step', () {
      final history = MatrixGridHistoryController();
      history.beginBatch();
      history.record(
        const MatrixRangeChange(
          rowIdx: 0,
          previousValue: null,
          newValue: '1',
        ),
      );
      history.record(
        const MatrixRangeChange(
          rowIdx: 1,
          previousValue: null,
          newValue: '2',
        ),
      );
      history.endBatch();

      final entry = history.popUndo();
      expect(entry, isNotNull);
      expect(entry!.changes, hasLength(2));
    });

    test('clears redo stack when a new change is recorded', () {
      final history = MatrixGridHistoryController();
      history.record(
        const MatrixRangeChange(
          rowIdx: 0,
          previousValue: null,
          newValue: '1',
        ),
      );

      final undone = history.popUndo()!;
      history.pushRedo(undone);
      expect(history.popRedo(), isNotNull);

      history.record(
        const MatrixRangeChange(
          rowIdx: 0,
          previousValue: '1',
          newValue: '2',
        ),
      );
      expect(history.popRedo(), isNull);
    });
  });
}
