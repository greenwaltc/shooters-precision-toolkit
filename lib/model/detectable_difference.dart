// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'project_form_model.dart';

/// Composite key used to look up a detectable-difference fraction for a
/// specific experimental design.
typedef _Key = ({int totalSamples, SampleSizeFamily family, RiskLevel risk});

/// Programmatic source of truth for the "detectable difference window" — the
/// fractional band around the grand mean within which an effect is considered
/// indistinguishable from noise for a given experimental design.
///
/// Backed by a static lookup table keyed by
/// `(totalSamples, SampleSizeFamily, RiskLevel)`. To add a new design, add a
/// row to [_table]; nothing else needs to change.
class DetectableDifference {
  const DetectableDifference._();

  /// Detectable-difference fractions for every supported design.
  ///
  /// Each entry mirrors one row of the canonical design matrix:
  /// `totalSamples, family, riskLevel → fraction`.
  ///
  /// Convention for newly-added designs whose calibrated value is not yet
  /// known: add an explicit entry with the placeholder value `0.5` and an
  /// inline `// TODO: calibrate` comment, so the missing calibration is
  /// discoverable by a code search rather than silently falling back at
  /// runtime.
  static const Map<_Key, double> _table = {
    // Simple A/B comparison
    (totalSamples: 8,  family: SampleSizeFamily.simpleComparison, risk: RiskLevel.tenPercent):  0.45,
    (totalSamples: 8,  family: SampleSizeFamily.simpleComparison, risk: RiskLevel.fivePercent): 0.52,
    (totalSamples: 8,  family: SampleSizeFamily.simpleComparison, risk: RiskLevel.onePercent):  0.66,
    (totalSamples: 14, family: SampleSizeFamily.simpleComparison, risk: RiskLevel.tenPercent):  0.34,
    (totalSamples: 14, family: SampleSizeFamily.simpleComparison, risk: RiskLevel.fivePercent): 0.40,
    (totalSamples: 14, family: SampleSizeFamily.simpleComparison, risk: RiskLevel.onePercent):  0.52,
    (totalSamples: 56, family: SampleSizeFamily.simpleComparison, risk: RiskLevel.tenPercent):  0.17,
    (totalSamples: 56, family: SampleSizeFamily.simpleComparison, risk: RiskLevel.fivePercent): 0.20,
    (totalSamples: 56, family: SampleSizeFamily.simpleComparison, risk: RiskLevel.onePercent):  0.26,

    // Factorial designs
    (totalSamples: 16, family: SampleSizeFamily.factorial, risk: RiskLevel.tenPercent):  0.31,
    (totalSamples: 16, family: SampleSizeFamily.factorial, risk: RiskLevel.fivePercent): 0.37,
    (totalSamples: 16, family: SampleSizeFamily.factorial, risk: RiskLevel.onePercent):  0.48,
    (totalSamples: 24, family: SampleSizeFamily.factorial, risk: RiskLevel.tenPercent):  0.25,
    (totalSamples: 24, family: SampleSizeFamily.factorial, risk: RiskLevel.fivePercent): 0.30,
    (totalSamples: 24, family: SampleSizeFamily.factorial, risk: RiskLevel.onePercent):  0.40,
    (totalSamples: 48, family: SampleSizeFamily.factorial, risk: RiskLevel.tenPercent):  0.18,
    (totalSamples: 48, family: SampleSizeFamily.factorial, risk: RiskLevel.fivePercent): 0.21,
    (totalSamples: 48, family: SampleSizeFamily.factorial, risk: RiskLevel.onePercent):  0.28,
  };

  /// Returns the detectable difference window as a fraction of the grand mean
  /// (e.g. `0.20` for a `±20%` window).
  ///
  /// Throws [ArgumentError] if no entry exists for the given
  /// `(totalSamples, family, riskLevel)`. New designs added to
  /// [SampleSizeCatalog] must be paired with an explicit row in [_table];
  /// see [_table]'s docstring for the placeholder convention when the
  /// calibrated value is not yet known.
  static double fractionFor({
    required int totalSamples,
    required SampleSizeFamily family,
    required RiskLevel riskLevel,
  }) {
    assert(totalSamples > 0, 'totalSamples must be positive');

    final value = _table[(
      totalSamples: totalSamples,
      family: family,
      risk: riskLevel,
    )];
    if (value == null) {
      throw ArgumentError(
        'No detectable-difference entry for '
        'totalSamples=$totalSamples, family=${family.name}, '
        'riskLevel=${riskLevel.name}. Add an explicit row to '
        'DetectableDifference._table (use 0.5 with a // TODO: calibrate '
        'comment if the real value is unknown).',
      );
    }
    return value;
  }

  /// Convenience overload that pulls [totalSamples] and [family] off a
  /// [SampleSizeOption].
  static double fractionForOption({
    required SampleSizeOption option,
    required RiskLevel riskLevel,
  }) {
    return fractionFor(
      totalSamples: option.totalSamples,
      family: option.family,
      riskLevel: riskLevel,
    );
  }

  /// Formats a detectable-difference fraction as a `±NN%` display string.
  ///
  /// `0.20` → `'±20%'`. Fractional inputs (e.g. `0.205`) are rendered with
  /// up to one decimal place.
  static String formatFraction(double fraction) {
    final percent = fraction * 100;
    final rendered = percent == percent.roundToDouble()
        ? percent.round().toString()
        : percent.toStringAsFixed(1);
    return '±$rendered%';
  }
}
