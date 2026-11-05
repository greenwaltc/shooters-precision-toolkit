import 'package:bramwells_precision_test_kit/features/experiments/api/factor_stats.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/models/effect_status.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/services/anomr_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

class _Readings extends Fake implements PlutoGridStateManager {
  _Readings(this.rows);
  @override
  final List<PlutoRow> rows;
}

void main() {
  group('ANOMR numerical contract', () {
    test('averages valid observed readings and imputes only missing data', () {
      final grid = _Readings([
        for (final value in ['1.25', null, '3/4', double.infinity, 'invalid'])
          PlutoRow(cells: {'range': PlutoCell(value: value)}),
      ]);
      expect(AnomrCalculator.collectRanges(grid), [1.25, .75]);
      // Canonical group-size units; 1e-12 is well below displayed precision.
      expect(
        AnomrCalculator.mean(AnomrCalculator.collectRanges(grid)),
        closeTo(1, 1e-12),
      );
      expect(AnomrCalculator.collectRanges(grid, imputeMissingData: true), [
        1.25,
        1,
        .75,
        1,
        1,
      ]);
      expect(AnomrCalculator.hasMissingRangeData(grid), isTrue);
      expect(
        AnomrCalculator.collectRanges(_Readings([]), imputeMissingData: true),
        isEmpty,
      );
      expect(AnomrCalculator.mean([]), isNaN);
    });
    test(
      'risk boundaries are inclusive and missing states remain insufficient',
      () {
        const atBounds = FactorStats(
          firstMean: 1,
          secondMean: 3,
          firstCount: 2,
          secondCount: 2,
        );
        expect(
          AnomrCalculator.computeStatus(
            stats: atBounds,
            lowerBound: 1,
            upperBound: 3,
          ),
          EffectStatus.notDetected,
        );
        const outside = FactorStats(
          firstMean: .5,
          secondMean: 3.5,
          firstCount: 2,
          secondCount: 2,
        );
        expect(
          AnomrCalculator.computeStatus(
            stats: outside,
            lowerBound: 1,
            upperBound: 3,
          ),
          EffectStatus.significant,
        );
        const partial = FactorStats(
          firstMean: .5,
          secondMean: 2,
          firstCount: 2,
          secondCount: 2,
        );
        expect(
          AnomrCalculator.computeStatus(
            stats: partial,
            lowerBound: 1,
            upperBound: 3,
          ),
          EffectStatus.marginal,
        );
        const missing = FactorStats(
          firstMean: 2,
          secondMean: double.nan,
          firstCount: 2,
          secondCount: 0,
        );
        expect(
          AnomrCalculator.computeStatus(
            stats: missing,
            lowerBound: 1,
            upperBound: 3,
          ),
          EffectStatus.insufficient,
        );
      },
    );
  });
}
