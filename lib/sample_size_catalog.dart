// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'model/project_form_model.dart';

// =============================================================================
//                          SAMPLE-SIZE OPTION CATALOG
// =============================================================================
//
// This file is the single source of truth for the sample-size choices that
// appear on the project form. To add, remove, or recalibrate an option:
//
//   1. Declare (or edit) a top-level `const SampleSizeOption` below.
//      * `numSets * setSize` = total samples.
//      * Provide a `detectableDifferences` entry for every [RiskLevel]
//        under which the option is offered. Use `0.5` with an inline
//        `// TODO: calibrate` comment as a discoverable placeholder.
//   2. Add the option to `SampleSizeCatalog._entries` under each
//      (ExperimentStructure, RiskLevel) pair where it should be visible.
//
// The same option `const` can appear in any number of (structure, risk)
// lists — there is no need to duplicate the calibrated values.
//
// To make a (structure, risk) combination show a different list of
// options entirely, just write a different list literal in `_entries`.
// =============================================================================

// ---------------------------------------------------------------------------
// Simple A/B comparison (1 factor, 2 states ⇒ setSize = 2).
// ---------------------------------------------------------------------------

const SampleSizeOption _simpleAB_8 = SampleSizeOption(
  groupSize: 2,
  numGroups: 4,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.45,
    RiskLevel.fivePercent: 0.52,
    RiskLevel.onePercent: 0.66,
  },
);

const SampleSizeOption _simpleAB_14 = SampleSizeOption(
  groupSize: 2,
  numGroups: 7,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.34,
    RiskLevel.fivePercent: 0.40,
    RiskLevel.onePercent: 0.52,
  },
);

const SampleSizeOption _simpleAB_56 = SampleSizeOption(
  groupSize: 2,
  numGroups: 28,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.17,
    RiskLevel.fivePercent: 0.20,
    RiskLevel.onePercent: 0.26,
  },
);

// ---------------------------------------------------------------------------
// Two-factor factorial (setSize = 4).
// totalSamples levels: 16, 24, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _twoFactor_16 = SampleSizeOption(
  groupSize: 4,
  numGroups: 4,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.31,
    RiskLevel.fivePercent: 0.37,
    RiskLevel.onePercent: 0.48,
  },
);

const SampleSizeOption _twoFactor_24 = SampleSizeOption(
  groupSize: 4,
  numGroups: 6,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.25,
    RiskLevel.fivePercent: 0.30,
    RiskLevel.onePercent: 0.40,
  },
);

const SampleSizeOption _twoFactor_48 = SampleSizeOption(
  groupSize: 4,
  numGroups: 12,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.18,
    RiskLevel.fivePercent: 0.21,
    RiskLevel.onePercent: 0.28,
  },
);

// ---------------------------------------------------------------------------
// Three-factor factorial (setSize = 8).
// totalSamples levels: 16, 24, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _threeFactor_16 = SampleSizeOption(
  groupSize: 8,
  numGroups: 2,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.31,
    RiskLevel.fivePercent: 0.37,
    RiskLevel.onePercent: 0.48,
  },
);

const SampleSizeOption _threeFactor_24 = SampleSizeOption(
  groupSize: 8,
  numGroups: 3,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.25,
    RiskLevel.fivePercent: 0.30,
    RiskLevel.onePercent: 0.40,
  },
);

const SampleSizeOption _threeFactor_48 = SampleSizeOption(
  groupSize: 8,
  numGroups: 6,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.18,
    RiskLevel.fivePercent: 0.21,
    RiskLevel.onePercent: 0.28,
  },
);

// ---------------------------------------------------------------------------
// Four-factor factorial (setSize = 16).
// totalSamples levels: 16, 24, 48. numSets = 1.5 is a half-fraction
// replication for the 24-sample design.
// ---------------------------------------------------------------------------

const SampleSizeOption _fourFactor_16 = SampleSizeOption(
  groupSize: 16,
  numGroups: 1,
  family: SampleSizeFamily.factorial,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.31,
    RiskLevel.fivePercent: 0.37,
    RiskLevel.onePercent: 0.48,
  },
);

// const SampleSizeOption _fourFactor_24 = SampleSizeOption(
//   groupSize: 1.5,
//   numGroups: 16,
//   family: SampleSizeFamily.factorial,
//   detectableDifferences: {
//     RiskLevel.tenPercent: 0.25,
//     RiskLevel.fivePercent: 0.30,
//     RiskLevel.onePercent: 0.40,
//   },
// );

const SampleSizeOption _fourFactor_48 = SampleSizeOption(
  groupSize: 16,
  numGroups: 3,
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
/// given combination of [ExperimentStructure] and [RiskLevel].
///
/// Each `(structure, riskLevel)` pair maps to an independently-editable
/// list of options, so future requirements like "for four-factor designs
/// at 1% risk, only offer 48-sample plans" become a one-line edit below.
class SampleSizeCatalog {
  const SampleSizeCatalog._();

  /// Per-(structure, risk-level) available options.
  ///
  /// To diverge the visible options by risk level, replace the shared list
  /// for a given inner key with a custom list literal — e.g.
  /// `RiskLevel.onePercent: [_simpleAB_14, _simpleAB_56]` to hide the
  /// 8-sample plan at the strictest risk level.
  static const Map<ExperimentStructure, Map<RiskLevel, List<SampleSizeOption>>>
      _entries = {
    ExperimentStructure.simpleABComparison: {
      RiskLevel.tenPercent: [_simpleAB_8, _simpleAB_14, _simpleAB_56],
      RiskLevel.fivePercent: [_simpleAB_8, _simpleAB_14, _simpleAB_56],
      RiskLevel.onePercent: [_simpleAB_8, _simpleAB_14, _simpleAB_56],
    },
    ExperimentStructure.twoFactors: {
      RiskLevel.tenPercent: [_twoFactor_16, _twoFactor_24, _twoFactor_48],
      RiskLevel.fivePercent: [_twoFactor_16, _twoFactor_24, _twoFactor_48],
      RiskLevel.onePercent: [_twoFactor_16, _twoFactor_24, _twoFactor_48],
    },
    ExperimentStructure.threeFactors: {
      RiskLevel.tenPercent: [_threeFactor_16, _threeFactor_24, _threeFactor_48],
      RiskLevel.fivePercent: [
        _threeFactor_16,
        _threeFactor_24,
        _threeFactor_48,
      ],
      RiskLevel.onePercent: [_threeFactor_16, _threeFactor_24, _threeFactor_48],
    },
    // ExperimentStructure.fourFactors: {
    //   RiskLevel.tenPercent: [_fourFactor_16, _fourFactor_24, _fourFactor_48],
    //   RiskLevel.fivePercent: [_fourFactor_16, _fourFactor_24, _fourFactor_48],
    //   RiskLevel.onePercent: [_fourFactor_16, _fourFactor_24, _fourFactor_48],
    // },
    ExperimentStructure.fourFactors: {
      RiskLevel.tenPercent: [_fourFactor_16, _fourFactor_48],
      RiskLevel.fivePercent: [_fourFactor_16, _fourFactor_48],
      RiskLevel.onePercent: [_fourFactor_16, _fourFactor_48],
    },
  };

  /// Returns the [SampleSizeOption]s the UI should offer for the given
  /// [structure] + [riskLevel] selection. Returns an empty list if no
  /// entry exists.
  static List<SampleSizeOption> optionsFor({
    required ExperimentStructure structure,
    required RiskLevel riskLevel,
  }) {
    return _entries[structure]?[riskLevel] ?? const [];
  }

  /// Resolves a persisted [SampleSizeOption] back to one of the catalog
  /// entries for the given [structure] + [riskLevel].
  ///
  /// Tries an exact-shape match first, then falls back to a `totalSamples`
  /// match (so saved projects keep the user's selection across catalog
  /// edits, factor-count changes, or risk-level changes). Returns the
  /// first option when nothing else applies.
  static SampleSizeOption resolveFromJson({
    required Map<String, dynamic>? json,
    required ExperimentStructure structure,
    required RiskLevel riskLevel,
  }) {
    final options = optionsFor(structure: structure, riskLevel: riskLevel);
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
