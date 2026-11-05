// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/foundation.dart';

import 'factor_row.dart';

/// Snapshot of all derived values needed to render the ANOMR results view
/// for a given (PlutoGrid state manager + project form model) combination.
@immutable
class AnomrSummary {
  /// Creates a summary with read-only copies of the measurements and chart
  /// rows.
  AnomrSummary({
    required List<double> ranges,
    required this.grandMean,
    required this.detectableDiffPercent,
    required this.lowerBound,
    required this.upperBound,
    required List<FactorRow> factorRows,
  }) : ranges = List.unmodifiable(ranges),
       factorRows = List.unmodifiable(factorRows);

  final List<double> ranges;
  final double grandMean;

  /// Detectable difference as a fraction of the grand mean (e.g. `0.31`).
  final double detectableDiffPercent;

  /// `grandMean * (1 - detectableDiffPercent)`.
  final double lowerBound;

  /// `grandMean * (1 + detectableDiffPercent)`.
  final double upperBound;

  final List<FactorRow> factorRows;

  /// Whether a chart can be built from the available measurements, mean, and
  /// factor rows.
  bool get hasEnoughData =>
      ranges.isNotEmpty && grandMean.isFinite && factorRows.isNotEmpty;
}
