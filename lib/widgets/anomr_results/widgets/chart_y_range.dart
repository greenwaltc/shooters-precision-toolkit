import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Inclusive Y-axis bounds returned by [ChartYRange.compute].
@immutable
class ChartYRangeValues {
  const ChartYRangeValues({required this.min, required this.max});

  final double min;
  final double max;
}

/// Computes a Y-range that contains every reference candidate plus a
/// proportional padding on either side.
class ChartYRange {
  const ChartYRange._();

  static ChartYRangeValues compute(Iterable<double> candidates) {
    final finite = candidates.where((value) => value.isFinite).toList();
    if (finite.isEmpty) {
      return const ChartYRangeValues(min: 0, max: 1);
    }

    var min = finite.reduce(math.min);
    var max = finite.reduce(math.max);
    final spread = max - min;
    if (spread == 0) {
      final adjustment = max.abs() * 0.1 + 1;
      min -= adjustment;
      max += adjustment;
    } else {
      min -= spread * 0.2;
      max += spread * 0.2;
    }
    return ChartYRangeValues(min: min, max: max);
  }
}
