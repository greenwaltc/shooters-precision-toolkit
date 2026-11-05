import '../../../shared/foundation/json_object.dart';

/// Supported experiment structures and their factor counts.
enum ExperimentStructure {
  simpleABComparison(1),
  twoFactors(2),
  threeFactors(3),
  fourFactors(4);

  const ExperimentStructure(this.factorCount);
  final int factorCount;

  /// Resolves a persisted enum name to a valid experiment structure.
  static ExperimentStructure fromName(String? name) {
    return ExperimentStructure.values.firstWhere(
      (structure) => structure.name == name,
      orElse: () => ExperimentStructure.simpleABComparison,
    );
  }
}

/// Risk levels offered by the sample-size calculator.
enum RiskLevel {
  tenPercent(0.10),
  fivePercent(0.05),
  onePercent(0.01);

  const RiskLevel(this.probability);

  final double probability;

  /// Resolves a persisted enum name to a valid risk level.
  static RiskLevel fromName(String? name) {
    return RiskLevel.values.firstWhere(
      (riskLevel) => riskLevel.name == name,
      orElse: () => RiskLevel.tenPercent,
    );
  }
}

/// Catalog family used to resolve comparable sample-size options.
enum SampleSizeFamily {
  simpleComparison,
  factorial;

  /// Resolves a persisted enum name to a valid sample-size family.
  static SampleSizeFamily fromName(String? name) {
    return SampleSizeFamily.values.firstWhere(
      (family) => family.name == name,
      orElse: () => SampleSizeFamily.simpleComparison,
    );
  }
}

/// Name and state labels for one factor in the experiment design.

final class FactorDefinition {
  const FactorDefinition({
    this.name = '',
    this.firstState = '',
    this.secondState = '',
  });

  final String name;
  final String firstState;
  final String secondState;

  /// Rehydrates a factor definition from persisted JSON.
  factory FactorDefinition.fromJson(Map<String, Object?> json) {
    return FactorDefinition(
      name: optionalJsonValue<String>(json, 'name') ?? '',
      firstState: optionalJsonValue<String>(json, 'firstState') ?? '',
      secondState: optionalJsonValue<String>(json, 'secondState') ?? '',
    );
  }

  /// Serializes this factor definition to JSON.
  Map<String, Object?> toJson() {
    return {'name': name, 'firstState': firstState, 'secondState': secondState};
  }
}

/// A single sample-size choice the user can select on the project form.
///
/// Identified by [numFactors] + [numSets] + [family]. The total number of
/// samples is [totalSamples] = [groupSize] * [numSets]:
///
/// * [numFactors] is the number of factors in the experiment design.
/// * [groupSize] is derived as `2^numFactors` — the cardinality of the
///   Cartesian product of factor-state combinations (i.e. the number of
///   groups in the design).
/// * [numSets] is the number of replicate ranges per group. Allowed to be
///   fractional (e.g. `1.5`) to support fractional-factorial designs.
///
/// Each option also carries its own [detectableDifferences] map — the
/// fractional band around the grand mean within which an effect is
/// considered indistinguishable from noise, keyed by [RiskLevel]. Listing
/// the values inline at construction time keeps the calibrated numbers
/// next to the option they describe, so adding or removing an option is a
/// single-place edit. See `lib/sample_size_catalog.dart` for the
/// declarations.
///
/// Equality is based on identity (`numFactors`, `numSets`, `family`) only,
/// so a [SampleSizeOption] decoded from JSON (with no detectable-difference
/// data) still matches its catalog counterpart for selection-resolution
/// purposes.

final class SampleSizeOption {
  SampleSizeOption({
    required this.numFactors,
    required this.numSets,
    required this.family,
    Map<RiskLevel, double> detectableDifferences = const {},
  }) : detectableDifferences = Map.unmodifiable(detectableDifferences);

  /// Number of factors in the experiment design.
  final int numFactors;

  /// Number of replicate ranges per group.
  final num numSets;

  final SampleSizeFamily family;

  /// Detectable-difference fraction (e.g. `0.20` → ±20%) for each
  /// [RiskLevel] under which this option is offered. Missing keys are
  /// treated as "not calibrated for that risk level" and will throw from
  /// [detectableDifferenceFor].
  final Map<RiskLevel, double> detectableDifferences;

  /// Number of groups in the design — `2^numFactors`.
  int get groupSize => 1 << numFactors;

  /// Total number of individual samples — `numSets * groupSize`, rounded to
  /// the nearest integer to absorb fractional-factorial replications.
  int get totalSamples => (numSets * groupSize).round();

  /// Number of replicate ranges per group.
  num get rangesPerGroup => numSets;

  /// Linear index used to persist a matrix range cell for [comboIdx] at
  /// replicate [blockIdx]. One-factor designs use state-major ordering; all
  /// other structures use replicate-major ordering.
  int matrixRangeIndex({
    required int comboIdx,
    required int blockIdx,
    required int comboCount,
    required ExperimentStructure structure,
  }) {
    final replicatesPerCombo = rangesPerGroup.toInt();
    if (structure == ExperimentStructure.simpleABComparison) {
      return comboIdx * replicatesPerCombo + blockIdx;
    }

    return blockIdx * comboCount + comboIdx;
  }

  /// Detectable-difference fraction of the grand mean for [riskLevel]
  /// (e.g. `0.20` for a ±20% window).
  double detectableDifferenceFor(RiskLevel riskLevel) {
    final value = detectableDifferences[riskLevel];
    if (value == null) {
      throw ArgumentError(
        'SampleSizeOption(numFactors: $numFactors, numSets: $numSets, '
        'family: ${family.name}) has no detectable-difference value for '
        '${riskLevel.name}. Add an entry to its detectableDifferences '
        'map in lib/sample_size_catalog.dart.',
      );
    }
    return value;
  }

  factory SampleSizeOption.fromJson(Map<String, Object?> json) {
    final persistedGroupSize = (optionalJsonValue<int>(json, 'setSize')) ?? 0;
    final numFactorsFromJson = optionalJsonValue<int>(json, 'numFactors');
    final numFactors =
        numFactorsFromJson ??
        (persistedGroupSize > 0
            ? _numFactorsForGroupSize(persistedGroupSize)
            : 0);

    return SampleSizeOption(
      numFactors: numFactors,
      numSets: (optionalJsonValue<num>(json, 'numSets')) ?? 0,
      family: SampleSizeFamily.fromName(
        optionalJsonValue<String>(json, 'family'),
      ),
    );
  }

  /// Identity-only — `detectableDifferences` is supplementary data
  /// resolved from the catalog after loading.
  Map<String, Object?> toJson() {
    return {
      'numFactors': numFactors,
      'numSets': numSets,
      'setSize': groupSize,
      'family': family.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SampleSizeOption &&
        other.numFactors == numFactors &&
        other.numSets == numSets &&
        other.family == family;
  }

  @override
  int get hashCode => Object.hash(numFactors, numSets, family);

  static int _numFactorsForGroupSize(int groupSize) {
    if (groupSize <= 0 || (groupSize & (groupSize - 1)) != 0) {
      return 0;
    }
    return groupSize.bitLength - 1;
  }
}
