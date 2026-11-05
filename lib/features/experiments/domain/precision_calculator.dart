import '../api/effect_status.dart';
import '../api/factor_stats.dart';
import '../api/test_design.dart';

/// One measured or unmeasured run of an experiment, with its factor states.
final class MatrixObservation {
  /// Creates an observation from the row's factor states and optional group
  /// size.
  ///
  /// Copies the factor states into a read-only list. A null [groupSize] marks
  /// an unmeasured row. Throws [ArgumentError] if a supplied size is not finite.
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

/// The measurements and risk bounds used to summarize an experiment.
final class PrecisionSummary {
  /// Creates a summary from measurements, their grand mean, and the calculated
  /// bounds.
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

/// Calculations for analysis of means for ranges (ANOMR).
///
/// Compares average group sizes across factor states using the chosen risk
/// bounds. A mean on a bound counts as inside. Rounding is left to the display.
abstract final class PrecisionCalculator {
  /// Returns the arithmetic mean of [values], or NaN when the list is empty.
  ///
  /// Throws [ArgumentError] if any measurement is not finite.
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

  /// Collects group sizes in row order.
  ///
  /// With [imputeMissingData] enabled, fills missing measurements with the
  /// observed mean when at least one measurement exists.
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

  /// Calculates means and counts for [firstState] and [secondState] at
  /// [factorIndex].
  ///
  /// Skips rows without that factor or a matching state. Missing group sizes
  /// use [imputeWith] when supplied.
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

  /// Classifies the two state means against [lowerBound] and [upperBound].
  ///
  /// Values on either bound count as inside. A missing state yields an
  /// insufficient result.
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

  /// Summarizes the observations with bounds based on [sample] and [risk].
  ///
  /// The grand mean uses observed values. [imputeMissingData] affects the
  /// returned measurement list.
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
