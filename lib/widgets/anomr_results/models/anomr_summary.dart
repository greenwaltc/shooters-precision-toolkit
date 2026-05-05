import 'package:flutter/foundation.dart';

import 'factor_row.dart';

/// Snapshot of all derived values needed to render the ANOMR results view
/// for a given (PlutoGrid state manager + project form model) combination.
@immutable
class AnomrSummary {
  const AnomrSummary({
    required this.ranges,
    required this.grandMean,
    required this.detectableDiffPercent,
    required this.lowerBound,
    required this.upperBound,
    required this.factorRows,
  });

  final List<double> ranges;
  final double grandMean;

  /// Detectable difference as a fraction of the grand mean (e.g. `0.31`).
  final double detectableDiffPercent;

  /// `grandMean * (1 - detectableDiffPercent)`.
  final double lowerBound;

  /// `grandMean * (1 + detectableDiffPercent)`.
  final double upperBound;

  final List<FactorRow> factorRows;

  bool get hasEnoughData =>
      ranges.isNotEmpty && grandMean.isFinite && factorRows.isNotEmpty;
}
