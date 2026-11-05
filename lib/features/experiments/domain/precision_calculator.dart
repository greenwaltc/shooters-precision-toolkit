import '../api/effect_status.dart';
import '../api/factor_stats.dart';
import '../api/test_design.dart';

/// Numeric input in canonical measurement units; no grid cells or chart colors.
final class MatrixObservation {
  MatrixObservation({
    required List<String> factorStates,
    required this.groupSize,
  }) : factorStates = List.unmodifiable(factorStates) {
    if (groupSize != null && !groupSize!.isFinite) {
      throw ArgumentError('Measurements must be finite.');
    }
  }
  final List<String> factorStates;
  final double? groupSize;
}

final class PrecisionSummary {
  PrecisionSummary({
    required List<double> ranges,
    required this.grandMean,
    required this.lowerBound,
    required this.upperBound,
    required this.fraction,
  }) : ranges = List.unmodifiable(ranges);
  final List<double> ranges;
  final double grandMean;
  final double lowerBound;
  final double upperBound;
  final double fraction;
}

/// ANOMR arithmetic. Risk bounds are inclusive; no rounding occurs here.
abstract final class PrecisionCalculator {
  static double mean(List<double> values) {
    if (values.isEmpty) {
      return double.nan;
    }
    if (values.any((value) => !value.isFinite)) {
      throw ArgumentError('Measurements must be finite.');
    }
    // Normalize before summing so valid large readings cannot overflow the sum.
    final magnitude = values.fold<double>(
      0,
      (largest, value) => value.abs() > largest ? value.abs() : largest,
    );
    if (magnitude == 0) {
      return 0;
    }
    final scaled = values.fold<double>(
      0,
      (sum, value) => sum + value / magnitude,
    );
    return (scaled / values.length) * magnitude;
  }

  static List<double> collectRanges(
    List<MatrixObservation> rows, {
    bool imputeMissingData = false,
  }) {
    final observed = rows
        .map((row) => row.groupSize)
        .whereType<double>()
        .toList(growable: false);
    if (!imputeMissingData || observed.isEmpty) {
      return observed;
    }
    final grandMean = mean(observed);
    return rows
        .map((row) => row.groupSize ?? grandMean)
        .toList(growable: false);
  }

  static FactorStats statsFor({
    required List<MatrixObservation> rows,
    required int factorIndex,
    required String firstState,
    required String secondState,
    double? imputeWith,
  }) {
    final first = <double>[];
    final second = <double>[];
    for (final row in rows) {
      final value = row.groupSize ?? imputeWith;
      if (value == null ||
          factorIndex < 0 ||
          factorIndex >= row.factorStates.length) {
        continue;
      }
      final state = row.factorStates[factorIndex];
      if (state == firstState) {
        first.add(value);
      } else if (state == secondState) {
        second.add(value);
      }
    }
    return FactorStats(
      firstMean: mean(first),
      secondMean: mean(second),
      firstCount: first.length,
      secondCount: second.length,
    );
  }

  static EffectStatus computeStatus({
    required FactorStats stats,
    required double lowerBound,
    required double upperBound,
  }) {
    if (!stats.hasBoth) {
      return EffectStatus.insufficient;
    }
    final firstOutside =
        stats.firstMean > upperBound || stats.firstMean < lowerBound;
    final secondOutside =
        stats.secondMean > upperBound || stats.secondMean < lowerBound;
    if (firstOutside && secondOutside) {
      return EffectStatus.significant;
    }
    if (!firstOutside && !secondOutside) {
      return EffectStatus.notDetected;
    }
    return EffectStatus.marginal;
  }

  static PrecisionSummary summarize({
    required List<MatrixObservation> rows,
    required SampleSizeOption sample,
    required RiskLevel risk,
    required bool imputeMissingData,
  }) {
    final observed = collectRanges(rows);
    final grandMean = mean(observed);
    final fraction = sample.detectableDifferenceFor(risk);
    return PrecisionSummary(
      ranges: collectRanges(rows, imputeMissingData: imputeMissingData),
      grandMean: grandMean,
      lowerBound: grandMean * (1 - fraction),
      upperBound: grandMean * (1 + fraction),
      fraction: fraction,
    );
  }
}
