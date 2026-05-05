import 'dart:math' as math;

import '../models/factor_row.dart';

/// Looks up [FactorRow] entries by chart x-coordinate.
///
/// Used by the chart's tooltip and tick-label callbacks.
class FactorRowLocator {
  const FactorRowLocator(this.rows);

  final List<FactorRow> rows;

  static const double _epsilon = 0.01;

  /// Returns the state label whose tick exactly matches [x], or `null`.
  String? stateLabelAt(double x) {
    for (final row in rows) {
      if ((x - row.firstX).abs() < _epsilon) return row.firstLabel;
      if ((x - row.secondX).abs() < _epsilon) return row.secondLabel;
    }
    return null;
  }

  /// Returns the [FactorRow] whose midpoint matches [x], or `null`.
  FactorRow? factorAtMidpoint(double x) {
    for (final row in rows) {
      if ((x - row.midpointX).abs() < _epsilon) return row;
    }
    return null;
  }

  /// Returns the [FactorRow] whose nearest endpoint is closest to [x].
  FactorRow? nearestFactor(double x) {
    FactorRow? best;
    double bestDist = double.infinity;
    for (final row in rows) {
      final d = math.min((x - row.firstX).abs(), (x - row.secondX).abs());
      if (d < bestDist) {
        bestDist = d;
        best = row;
      }
    }
    return best;
  }

  /// Returns the state label of [row] whose endpoint is closest to [x].
  String stateLabelNearest(double x, FactorRow row) {
    return (x - row.firstX).abs() < (x - row.secondX).abs()
        ? row.firstLabel
        : row.secondLabel;
  }
}
