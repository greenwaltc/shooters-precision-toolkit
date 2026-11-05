import 'package:bramwells_precision_test_kit/features/experiments/api/effect_status.dart';
import 'package:bramwells_precision_test_kit/features/experiments/domain/precision_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mean preserves canonical units without overflowing finite readings',
    () {
      expect(PrecisionCalculator.mean([1e308, 1e308]), closeTo(1e308, 1e293));
      expect(PrecisionCalculator.mean([-1e308, 1e308]), 0);
      expect(PrecisionCalculator.mean([0, 0]), 0);
      expect(PrecisionCalculator.mean([]), isNaN);
      for (final value in [double.nan, double.infinity, -double.infinity]) {
        expect(() => PrecisionCalculator.mean([value]), throwsArgumentError);
        expect(
          () => MatrixObservation(factorStates: [], groupSize: value),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'factor counts exclude missing readings unless imputation is explicit',
    () {
      final rows = [
        MatrixObservation(factorStates: ['A'], groupSize: 1),
        MatrixObservation(factorStates: ['A'], groupSize: null),
        MatrixObservation(factorStates: ['B'], groupSize: 3),
      ];
      final stats = PrecisionCalculator.statsFor(
        rows: rows,
        factorIndex: 0,
        firstState: 'A',
        secondState: 'B',
      );
      expect(stats.firstCount, 1);
      expect(stats.secondMean, 3);
      final imputed = PrecisionCalculator.statsFor(
        rows: rows,
        factorIndex: 0,
        firstState: 'A',
        secondState: 'B',
        imputeWith: 2,
      );
      expect(imputed.firstMean, 1.5);
      expect(imputed.firstCount, 2);
      expect(PrecisionCalculator.collectRanges(rows, imputeMissingData: true), [
        1,
        2,
        3,
      ]);
      expect(
        PrecisionCalculator.computeStatus(
          stats: stats,
          lowerBound: 1,
          upperBound: 3,
        ),
        EffectStatus.notDetected,
      );
      expect(
        PrecisionCalculator.statsFor(
          rows: rows,
          factorIndex: 4,
          firstState: 'A',
          secondState: 'B',
        ).hasBoth,
        isFalse,
      );
    },
  );
}
