// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.


// 32 obs, 0.1, 0.780-1.220
// 32 obs, 0.05, 0.739-1.261
// 32 obs, 0.01, 0.659-1.341


import 'model/project_form_model.dart';

// =============================================================================
//                          SAMPLE-SIZE OPTION CATALOG
// =============================================================================
//
// This file is the single source of truth for the sample-size choices that
// appear on the project form. To add, remove, or recalibrate an option:
//
//   1. Declare (or edit) a top-level `const SampleSizeOption` below.
//      * Set `numFactors` to match the factor-count section the option
//        belongs to. `groupSize` is derived automatically as `2^numFactors`.
//      * `numSets * groupSize` = total samples.
//      * Provide a `detectableDifferences` entry for every [RiskLevel]
//        under which the option is offered. Use `0.5` with an inline
//        `// TODO: calibrate` comment as a discoverable placeholder.
//   2. Add the option to `SampleSizeCatalog._entries` under each
//      (factorCount, RiskLevel) pair where it should be visible.
//
// The same option `const` can appear in any number of (factorCount, risk)
// lists — there is no need to duplicate the calibrated values.
//
// To make a (factorCount, risk) combination show a different list of
// options entirely, just write a different list literal in `_entries`.
// =============================================================================

// ---------------------------------------------------------------------------
// One factor (numFactors = 1 ⇒ groupSize = 2).
// totalSamples levels: 8, 14, 56.
// ---------------------------------------------------------------------------

const SampleSizeOption _oneFactor_8 = SampleSizeOption(
  numFactors: 1,
  numSets: 4,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.45,
    RiskLevel.fivePercent: 0.52,
    RiskLevel.onePercent: 0.66,
  },
);

const SampleSizeOption _oneFactor_14 = SampleSizeOption(
  numFactors: 1,
  numSets: 7,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.34,
    RiskLevel.fivePercent: 0.40,
    RiskLevel.onePercent: 0.52,
  },
);

const SampleSizeOption _oneFactor_56 = SampleSizeOption(
  numFactors: 1,
  numSets: 28,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.17,
    RiskLevel.fivePercent: 0.20,
    RiskLevel.onePercent: 0.26,
  },
);

// ---------------------------------------------------------------------------
// Two factors (numFactors = 2 ⇒ groupSize = 4).
// totalSamples levels: 16, 24, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _twoFactor_16 = SampleSizeOption(
  numFactors: 2,
  numSets: 4,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.31,
    RiskLevel.fivePercent: 0.37,
    RiskLevel.onePercent: 0.48,
  },
);

const SampleSizeOption _twoFactor_24 = SampleSizeOption(
  numFactors: 2,
  numSets: 6,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.25,
    RiskLevel.fivePercent: 0.30,
    RiskLevel.onePercent: 0.40,
  },
);

const SampleSizeOption _twoFactor_48 = SampleSizeOption(
  numFactors: 2,
  numSets: 12,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.18,
    RiskLevel.fivePercent: 0.21,
    RiskLevel.onePercent: 0.28,
  },
);

// ---------------------------------------------------------------------------
// Three factors (numFactors = 3 ⇒ groupSize = 8).
// totalSamples levels: 16, 24, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _threeFactor_16 = SampleSizeOption(
  numFactors: 3,
  numSets: 2,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.31,
    RiskLevel.fivePercent: 0.37,
    RiskLevel.onePercent: 0.48,
  },
);

const SampleSizeOption _threeFactor_24 = SampleSizeOption(
  numFactors: 3,
  numSets: 3,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.25,
    RiskLevel.fivePercent: 0.30,
    RiskLevel.onePercent: 0.40,
  },
);

const SampleSizeOption _threeFactor_48 = SampleSizeOption(
  numFactors: 3,
  numSets: 6,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.18,
    RiskLevel.fivePercent: 0.21,
    RiskLevel.onePercent: 0.28,
  },
);

// ---------------------------------------------------------------------------
// Four factors (numFactors = 4 ⇒ groupSize = 16).
// totalSamples levels: 16, 24, 48. numSets = 1.5 is a half-fraction
// replication for the 24-sample design.
// ---------------------------------------------------------------------------

const SampleSizeOption _fourFactor_16 = SampleSizeOption(
  numFactors: 4,
  numSets: 1,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.31,
    RiskLevel.fivePercent: 0.37,
    RiskLevel.onePercent: 0.48,
  },
);

// const SampleSizeOption _fourFactor_24 = SampleSizeOption(
//   numFactors: 4,
//   numSets: 1.5,
//   family: SampleSizeFamily.factorial,
//   detectableDifferences: {
//     RiskLevel.tenPercent: 0.25,
//     RiskLevel.fivePercent: 0.30,
//     RiskLevel.onePercent: 0.40,
//   },
// );

const SampleSizeOption _fourFactor_48 = SampleSizeOption(
  numFactors: 4,
  numSets: 3,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.18,
    RiskLevel.fivePercent: 0.21,
    RiskLevel.onePercent: 0.28,
  },
);

// ---------------------------------------------------------------------------
// Catalog.
// ---------------------------------------------------------------------------

/// Source of truth for which [SampleSizeOption]s appear in the UI for a
/// given combination of factor count and [RiskLevel].
///
/// Each `(factorCount, riskLevel)` pair maps to an independently-editable
/// list of options, so future requirements like "for four-factor designs
/// at 1% risk, only offer 48-sample plans" become a one-line edit below.
class SampleSizeCatalog {
  const SampleSizeCatalog._();

  /// Per-(factor-count, risk-level) available options.
  ///
  /// To diverge the visible options by risk level, replace the shared list
  /// for a given inner key with a custom list literal — e.g.
  /// `RiskLevel.onePercent: [_oneFactor_14, _oneFactor_56]` to hide the
  /// 8-sample plan at the strictest risk level.
  static const Map<int, Map<RiskLevel, List<SampleSizeOption>>> _entries = {
    1: {
      RiskLevel.tenPercent: [_oneFactor_8, _oneFactor_14, _oneFactor_56],
      RiskLevel.fivePercent: [_oneFactor_8, _oneFactor_14, _oneFactor_56],
      RiskLevel.onePercent: [_oneFactor_8, _oneFactor_14, _oneFactor_56],
    },
    2: {
      RiskLevel.tenPercent: [_twoFactor_16, _twoFactor_24, _twoFactor_48],
      RiskLevel.fivePercent: [_twoFactor_16, _twoFactor_24, _twoFactor_48],
      RiskLevel.onePercent: [_twoFactor_16, _twoFactor_24, _twoFactor_48],
    },
    3: {
      RiskLevel.tenPercent: [_threeFactor_16, _threeFactor_24, _threeFactor_48],
      RiskLevel.fivePercent: [
        _threeFactor_16,
        _threeFactor_24,
        _threeFactor_48,
      ],
      RiskLevel.onePercent: [_threeFactor_16, _threeFactor_24, _threeFactor_48],
    },
    4: {
      RiskLevel.tenPercent: [_fourFactor_16, _fourFactor_48],
      RiskLevel.fivePercent: [_fourFactor_16, _fourFactor_48],
      RiskLevel.onePercent: [_fourFactor_16, _fourFactor_48],
    },
  };

  /// Returns the [SampleSizeOption]s the UI should offer for the given
  /// [factorCount] + [riskLevel] selection. Returns an empty list if no
  /// entry exists.
  static List<SampleSizeOption> optionsFor({
    required int factorCount,
    required RiskLevel riskLevel,
  }) {
    return _entries[factorCount]?[riskLevel] ?? const [];
  }

  /// Resolves a persisted [SampleSizeOption] back to one of the catalog
  /// entries for the given [factorCount] + [riskLevel].
  ///
  /// Tries an exact-shape match first, then falls back to a `totalSamples`
  /// match (so saved projects keep the user's selection across catalog
  /// edits, factor-count changes, or risk-level changes). Returns the
  /// first option when nothing else applies.
  static SampleSizeOption resolveFromJson({
    required Map<String, dynamic>? json,
    required int factorCount,
    required RiskLevel riskLevel,
  }) {
    final options = optionsFor(factorCount: factorCount, riskLevel: riskLevel);
    if (options.isEmpty) {
      throw StateError(
        'No sample-size options configured for factorCount=$factorCount, '
        'riskLevel=${riskLevel.name}.',
      );
    }
    if (json == null) return options.first;

    final candidate = SampleSizeOption.fromJson(json);
    return options.firstWhere(
      (option) => option == candidate,
      orElse: () => options.firstWhere(
        (option) => option.totalSamples == candidate.totalSamples,
        orElse: () => options.first,
      ),
    );
  }
}
