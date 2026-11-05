// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import '../api/test_design.dart';

// =============================================================================
//                          SAMPLE-SIZE OPTION CATALOG
// =============================================================================

const _sixteenSampleRiskLevels = {
  RiskLevel.tenPercent: 0.314,
  RiskLevel.fivePercent: 0.371,
  RiskLevel.onePercent: 0.481,
};

const _thirtyTwoSampleRiskLevels = {
  RiskLevel.tenPercent: 0.22,
  RiskLevel.fivePercent: 0.261,
  RiskLevel.onePercent: 0.341,
};

const _fortyEightSampleRiskLevels = {
  RiskLevel.tenPercent: 0.179,
  RiskLevel.fivePercent: 0.213,
  RiskLevel.onePercent: 0.281,
};

// ---------------------------------------------------------------------------
// One factor (numFactors = 1 ⇒ groupSize = 2).
// totalSamples levels: 8, 14, 56.
// ---------------------------------------------------------------------------

final SampleSizeOption _oneFactor8 = SampleSizeOption(
  numFactors: 1,
  numSets: 4,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.45,
    RiskLevel.fivePercent: 0.52,
    RiskLevel.onePercent: 0.66,
  },
);

final SampleSizeOption _oneFactor14 = SampleSizeOption(
  numFactors: 1,
  numSets: 7,
  family: SampleSizeFamily.simpleComparison,
  detectableDifferences: {
    RiskLevel.tenPercent: 0.34,
    RiskLevel.fivePercent: 0.40,
    RiskLevel.onePercent: 0.52,
  },
);

final SampleSizeOption _oneFactor56 = SampleSizeOption(
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

final SampleSizeOption _twoFactor16 = SampleSizeOption(
  numFactors: 2,
  numSets: 4,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _sixteenSampleRiskLevels,
);

final SampleSizeOption _twoFactor32 = SampleSizeOption(
  numFactors: 2,
  numSets: 8,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _thirtyTwoSampleRiskLevels,
);

final SampleSizeOption _twoFactor48 = SampleSizeOption(
  numFactors: 2,
  numSets: 12,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _fortyEightSampleRiskLevels,
);

// ---------------------------------------------------------------------------
// Three factors (numFactors = 3 ⇒ groupSize = 8).
// totalSamples levels: 16, 32, 48.
// ---------------------------------------------------------------------------

final SampleSizeOption _threeFactor16 = SampleSizeOption(
  numFactors: 3,
  numSets: 2,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _sixteenSampleRiskLevels,
);

final SampleSizeOption _threeFactor32 = SampleSizeOption(
  numFactors: 3,
  numSets: 4,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _thirtyTwoSampleRiskLevels,
);

final SampleSizeOption _threeFactor48 = SampleSizeOption(
  numFactors: 3,
  numSets: 6,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _fortyEightSampleRiskLevels,
);

// ---------------------------------------------------------------------------
// Four factors (numFactors = 4 ⇒ groupSize = 16).
// totalSamples levels: 16, 32, 48.
// ---------------------------------------------------------------------------

final SampleSizeOption _fourFactor16 = SampleSizeOption(
  numFactors: 4,
  numSets: 1,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _sixteenSampleRiskLevels,
);

final SampleSizeOption _fourFactor32 = SampleSizeOption(
  numFactors: 4,
  numSets: 2,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _thirtyTwoSampleRiskLevels,
);

final SampleSizeOption _fourFactor48 = SampleSizeOption(
  numFactors: 4,
  numSets: 3,
  family: SampleSizeFamily.factorial,
  detectableDifferences: _fortyEightSampleRiskLevels,
);

// ---------------------------------------------------------------------------
// Catalog Implementation
// ---------------------------------------------------------------------------

/// The available sample plans and their detectable differences at each risk
/// level.
class SampleSizeCatalog {
  const SampleSizeCatalog._();

  static final Map<int, Map<RiskLevel, List<SampleSizeOption>>> _entries = {
    1: {
      RiskLevel.tenPercent: [_oneFactor8, _oneFactor14, _oneFactor56],
      RiskLevel.fivePercent: [_oneFactor8, _oneFactor14, _oneFactor56],
      RiskLevel.onePercent: [_oneFactor8, _oneFactor14, _oneFactor56],
    },
    2: {
      RiskLevel.tenPercent: [_twoFactor16, _twoFactor32, _twoFactor48],
      RiskLevel.fivePercent: [_twoFactor16, _twoFactor32, _twoFactor48],
      RiskLevel.onePercent: [_twoFactor16, _twoFactor32, _twoFactor48],
    },
    3: {
      RiskLevel.tenPercent: [_threeFactor16, _threeFactor32, _threeFactor48],
      RiskLevel.fivePercent: [_threeFactor16, _threeFactor32, _threeFactor48],
      RiskLevel.onePercent: [_threeFactor16, _threeFactor32, _threeFactor48],
    },
    4: {
      RiskLevel.tenPercent: [_fourFactor16, _fourFactor32, _fourFactor48],
      RiskLevel.fivePercent: [_fourFactor16, _fourFactor32, _fourFactor48],
      RiskLevel.onePercent: [_fourFactor16, _fourFactor32, _fourFactor48],
    },
  };

  /// Returns the [SampleSizeOption]s the UI should offer for the given
  /// [factorCount] + [riskLevel] selection.
  static List<SampleSizeOption> optionsFor({
    required int factorCount,
    required RiskLevel riskLevel,
  }) {
    return List.unmodifiable(_entries[factorCount]?[riskLevel] ?? const []);
  }

  /// Resolves a persisted [SampleSizeOption] back to one of the catalog
  /// entries.
  static SampleSizeOption resolveFromJson({
    required Map<String, Object?>? json,
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
    if (json == null) {
      return options.first;
    }

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
