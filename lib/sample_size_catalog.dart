// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'model/project_form_model.dart';

// =============================================================================
//                          SAMPLE-SIZE OPTION CATALOG
// =============================================================================

const _16sample_riskLevels = {
  RiskLevel.tenPercent: 0.314,
  RiskLevel.fivePercent: 0.371,
  RiskLevel.onePercent: 0.481,
};

const _32sample_riskLevels = {
  RiskLevel.tenPercent: 0.22,
  RiskLevel.fivePercent: 0.261,
  RiskLevel.onePercent: 0.341,
};

const _48sample_riskLevels = {
  RiskLevel.tenPercent: 0.179,
  RiskLevel.fivePercent: 0.213,
  RiskLevel.onePercent: 0.281,
};

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
// totalSamples levels: 16, 32, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _twoFactor_16 = SampleSizeOption(
  numFactors: 2,
  numSets: 4,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _16sample_riskLevels,
);

const SampleSizeOption _twoFactor_32 = SampleSizeOption(
  numFactors: 2,
  numSets: 8,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _32sample_riskLevels,
);

const SampleSizeOption _twoFactor_48 = SampleSizeOption(
  numFactors: 2,
  numSets: 12,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _48sample_riskLevels,
);

// ---------------------------------------------------------------------------
// Three factors (numFactors = 3 ⇒ groupSize = 8).
// totalSamples levels: 16, 32, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _threeFactor_16 = SampleSizeOption(
  numFactors: 3,
  numSets: 2,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _16sample_riskLevels,
);

const SampleSizeOption _threeFactor_32 = SampleSizeOption(
  numFactors: 3,
  numSets: 4,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _32sample_riskLevels,
);

const SampleSizeOption _threeFactor_48 = SampleSizeOption(
  numFactors: 3,
  numSets: 6,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _48sample_riskLevels,
);

// ---------------------------------------------------------------------------
// Four factors (numFactors = 4 ⇒ groupSize = 16).
// totalSamples levels: 16, 32, 48.
// ---------------------------------------------------------------------------

const SampleSizeOption _fourFactor_16 = SampleSizeOption(
  numFactors: 4,
  numSets: 1,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _16sample_riskLevels,
);

const SampleSizeOption _fourFactor_32 = SampleSizeOption(
  numFactors: 4,
  numSets: 2,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _32sample_riskLevels,
);

const SampleSizeOption _fourFactor_48 = SampleSizeOption(
  numFactors: 4,
  numSets: 3,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _48sample_riskLevels,
);

// ---------------------------------------------------------------------------
// Catalog Implementation
// ---------------------------------------------------------------------------

class SampleSizeCatalog {
  const SampleSizeCatalog._();

  static const Map<int, Map<RiskLevel, List<SampleSizeOption>>> _entries = {
    1: {
      RiskLevel.tenPercent: [_oneFactor_8, _oneFactor_14, _oneFactor_56],
      RiskLevel.fivePercent: [_oneFactor_8, _oneFactor_14, _oneFactor_56],
      RiskLevel.onePercent: [_oneFactor_8, _oneFactor_14, _oneFactor_56],
    },
    2: {
      RiskLevel.tenPercent: [_twoFactor_16, _twoFactor_32, _twoFactor_48],
      RiskLevel.fivePercent: [_twoFactor_16, _twoFactor_32, _twoFactor_48],
      RiskLevel.onePercent: [_twoFactor_16, _twoFactor_32, _twoFactor_48],
    },
    3: {
      RiskLevel.tenPercent: [_threeFactor_16, _threeFactor_32, _threeFactor_48],
      RiskLevel.fivePercent: [_threeFactor_16, _threeFactor_32, _threeFactor_48],
      RiskLevel.onePercent: [_threeFactor_16, _threeFactor_32, _threeFactor_48],
    },
    4: {
      RiskLevel.tenPercent: [_fourFactor_16, _fourFactor_32, _fourFactor_48],
      RiskLevel.fivePercent: [_fourFactor_16, _fourFactor_32, _fourFactor_48],
      RiskLevel.onePercent: [_fourFactor_16, _fourFactor_32, _fourFactor_48],
    },
  };

  /// Returns the [SampleSizeOption]s the UI should offer for the given
  /// [factorCount] + [riskLevel] selection.
  static List<SampleSizeOption> optionsFor({
    required int factorCount,
    required RiskLevel riskLevel,
  }) {
    return _entries[factorCount]?[riskLevel] ?? const [];
  }

  /// Resolves a persisted [SampleSizeOption] back to one of the catalog
  /// entries.
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
