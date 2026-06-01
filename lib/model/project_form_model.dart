// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../config/project_configuration.dart';
import '../sample_size_catalog.dart';

/// Supported experiment structures and their factor counts.
enum ExperimentStructure {
  simpleABComparison(
    label: 'Test How One Factor (two states) Influences Precision',
    factorCount: 1,
    usesFactorialSamplePlan: false,
  ),
  twoFactors(label: 'Test How Two Factors Influence Precision', factorCount: 2),
  threeFactors(
    label: 'Test How Three Factors Influence Precision',
    factorCount: 3,
  ),
  fourFactors(
    label: 'Test How Four Factors Influence Precision',
    factorCount: 4,
  );

  const ExperimentStructure({
    required this.label,
    required this.factorCount,
    this.usesFactorialSamplePlan = true,
  });

  final String label;
  final int factorCount;
  final bool usesFactorialSamplePlan;

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
  tenPercent('10%'),
  fivePercent('5%'),
  onePercent('1%');

  const RiskLevel(this.label);

  final String label;

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
@immutable
class FactorDefinition {
  const FactorDefinition({
    this.name = '',
    this.firstState = '',
    this.secondState = '',
  });

  final String name;
  final String firstState;
  final String secondState;

  /// Rehydrates a factor definition from persisted JSON.
  factory FactorDefinition.fromJson(Map<String, dynamic> json) {
    return FactorDefinition(
      name: json['name'] as String? ?? '',
      firstState: json['firstState'] as String? ?? '',
      secondState: json['secondState'] as String? ?? '',
    );
  }

  /// Serializes this factor definition to JSON.
  Map<String, dynamic> toJson() {
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
@immutable
class SampleSizeOption {
  const SampleSizeOption({
    required this.numFactors,
    required this.numSets,
    required this.family,
    this.detectableDifferences = const {},
  });

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

  /// Alias for [groupSize] — one group per Cartesian-product cell.
  int get groupCount => groupSize;

  /// Number of replicate ranges per group.
  num get rangesPerGroup => numSets;

  /// Display label, e.g. `"16 total ranges in 4 replicates of 4 ranges each"`.
  ///
  /// For [ExperimentStructure.simpleABComparison], replicates and ranges-per-
  /// replicate are swapped in the label so the two factor states read as
  /// replicates and [numSets] reads as ranges within each state.
  String labelFor(ExperimentStructure structure) {
    if (structure == ExperimentStructure.simpleABComparison) {
      final replicates = _formatSampleValue(groupSize);
      final rangesEach = _formatSampleValue(numSets);
      return '$totalSamples total ranges in $replicates replicates of '
          '$rangesEach ranges each';
    }

    return label;
  }

  /// Default factorial-style label shared by multi-factor experiment structures.
  String get label {
    final replicates = _formatSampleValue(rangesPerGroup);
    return '$totalSamples total ranges in $replicates replicates of '
        '$groupSize ranges each';
  }

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

  /// Convenience: pre-formatted "±NN%" label for this option at
  /// [riskLevel].
  String detectableDifferenceLabel(RiskLevel riskLevel) {
    return formatFraction(detectableDifferenceFor(riskLevel));
  }

  factory SampleSizeOption.fromJson(Map<String, dynamic> json) {
    final persistedGroupSize = (json['setSize'] as int?) ?? 0;
    final numFactorsFromJson = json['numFactors'] as int?;
    final numFactors =
        numFactorsFromJson ??
        (persistedGroupSize > 0
            ? _numFactorsForGroupSize(persistedGroupSize)
            : 0);

    return SampleSizeOption(
      numFactors: numFactors,
      numSets: (json['numSets'] as num?) ?? 0,
      family: SampleSizeFamily.fromName(json['family'] as String?),
    );
  }

  /// Identity-only — `detectableDifferences` is supplementary data
  /// resolved from the catalog after loading.
  Map<String, dynamic> toJson() {
    return {
      'numFactors': numFactors,
      'numSets': numSets,
      'setSize': groupSize,
      'family': family.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SampleSizeOption &&
        other.numFactors == numFactors &&
        other.numSets == numSets &&
        other.family == family;
  }

  @override
  int get hashCode => Object.hash(numFactors, numSets, family);

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

  static int _numFactorsForGroupSize(int groupSize) {
    if (groupSize <= 0 || (groupSize & (groupSize - 1)) != 0) return 0;
    return groupSize.bitLength - 1;
  }

  static String _formatSampleValue(num value) {
    final asDouble = value.toDouble();
    return asDouble == asDouble.roundToDouble()
        ? asDouble.round().toString()
        : asDouble.toStringAsFixed(1);
  }
}

/// Mutable project setup state used by the form and downstream matrix.
class ProjectFormModel extends ChangeNotifier {
  ProjectFormModel({
    this.projectTitle = '',
    this.experimentStructure = ExperimentStructure.simpleABComparison,
    this.riskLevel = RiskLevel.tenPercent,
    SampleSizeOption? sampleSizeOption,
    List<FactorDefinition>? factorDefinitions,
    this.imputeMissingData = false,
  }) : sampleSizeOption =
           sampleSizeOption ??
           SampleSizeCatalog.optionsFor(
             factorCount: experimentStructure.factorCount,
             riskLevel: riskLevel,
           ).first,
       _factorDefinitions = _normalizedFactorDefinitions(
         experimentStructure,
         factorDefinitions,
       ) {
    _ensureSampleSizeOptionIsValid();
  }

  String projectTitle;
  ExperimentStructure experimentStructure;
  RiskLevel riskLevel;
  SampleSizeOption sampleSizeOption;
  bool imputeMissingData;

  final List<FactorDefinition> _factorDefinitions;

  /// Rehydrates form state from persisted JSON.
  factory ProjectFormModel.fromJson(Map<String, dynamic> json) {
    final structure = ExperimentStructure.fromName(
      json['experimentStructure'] as String?,
    );
    final sampleSizeJson = json['sampleSizeOption'] is Map<String, dynamic>
        ? json['sampleSizeOption'] as Map<String, dynamic>
        : null;

    final risk = RiskLevel.fromName(json['riskLevel'] as String?);

    return ProjectFormModel(
      projectTitle: json['projectTitle'] as String? ?? '',
      experimentStructure: structure,
      riskLevel: risk,
      sampleSizeOption: SampleSizeCatalog.resolveFromJson(
        json: sampleSizeJson,
        factorCount: structure.factorCount,
        riskLevel: risk,
      ),
      factorDefinitions: _factorDefinitionsFromJson(json['factorDefinitions']),
      imputeMissingData: json['imputeMissingData'] as bool? ?? false,
    );
  }

  /// Immutable view of the active factor definitions.
  List<FactorDefinition> get factorDefinitions {
    return List.unmodifiable(_factorDefinitions);
  }

  /// Whether the impute-missing-data capability is enabled for this app build.
  bool get canImputeMissingData => ProjectConfiguration.current.featureFlags
      .isEnabled(FeatureFlag.imputeMissingData);

  /// Whether missing range cells should be filled with the grand mean.
  bool get shouldImputeMissingData => canImputeMissingData && imputeMissingData;

  /// Whether the form satisfies the same requirements enforced by submit
  /// validation on [ProjectForm].
  bool get isSetupValid {
    if (projectTitle.trim().isEmpty) return false;

    final normalizedFactorNames = <String>{};
    for (final factor in factorDefinitions) {
      final name = factor.name.trim();
      final firstState = factor.firstState.trim();
      final secondState = factor.secondState.trim();

      if (name.isEmpty || firstState.isEmpty || secondState.isEmpty) {
        return false;
      }

      if (firstState.toLowerCase() == secondState.toLowerCase()) {
        return false;
      }

      final normalizedName = name.toLowerCase();
      if (normalizedFactorNames.contains(normalizedName)) {
        return false;
      }
      normalizedFactorNames.add(normalizedName);
    }

    return true;
  }

  /// Serializes this form state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'projectTitle': projectTitle,
      'experimentStructure': experimentStructure.name,
      'riskLevel': riskLevel.name,
      'sampleSizeOption': sampleSizeOption.toJson(),
      'factorDefinitions': _factorDefinitions
          .map((definition) => definition.toJson())
          .toList(),
      'imputeMissingData': imputeMissingData,
    };
  }

  /// Updates the project title and notifies listeners when it changes.
  void setProjectTitle(String title) {
    if (projectTitle == title) return;

    projectTitle = title;
    notifyListeners();
  }

  /// Updates the experiment structure and resizes factor definitions.
  void setExperimentStructure(ExperimentStructure structure) {
    if (experimentStructure == structure) return;

    experimentStructure = structure;
    _resizeFactorDefinitions(structure.factorCount);
    _ensureSampleSizeOptionIsValid();
    notifyListeners();
  }

  /// Updates one factor definition by index.
  void setFactorDefinition({
    required int index,
    required String name,
    required String firstState,
    required String secondState,
  }) {
    if (index < 0 || index >= _factorDefinitions.length) return;

    final nextDefinition = FactorDefinition(
      name: name,
      firstState: firstState,
      secondState: secondState,
    );

    if (_factorDefinitions[index].name == nextDefinition.name &&
        _factorDefinitions[index].firstState == nextDefinition.firstState &&
        _factorDefinitions[index].secondState == nextDefinition.secondState) {
      return;
    }

    _factorDefinitions[index] = nextDefinition;
    notifyListeners();
  }

  /// Updates the selected risk level and reconciles sample-size options.
  void setRiskLevel(RiskLevel level) {
    if (riskLevel == level) return;

    riskLevel = level;
    _ensureSampleSizeOptionIsValid();
    notifyListeners();
  }

  /// Updates the selected sample-size option.
  void setSampleSizeOption(SampleSizeOption option) {
    if (sampleSizeOption == option) return;

    sampleSizeOption = option;
    notifyListeners();
  }

  /// Enables or disables missing-data imputation when the feature is active.
  void setImputeMissingData(bool shouldImpute) {
    if (!canImputeMissingData) {
      shouldImpute = false;
    }
    if (imputeMissingData == shouldImpute) return;

    imputeMissingData = shouldImpute;
    notifyListeners();
  }

  void _resizeFactorDefinitions(int factorCount) {
    if (_factorDefinitions.length > factorCount) {
      _factorDefinitions.removeRange(factorCount, _factorDefinitions.length);
    }

    while (_factorDefinitions.length < factorCount) {
      _factorDefinitions.add(const FactorDefinition());
    }
  }

  void _ensureSampleSizeOptionIsValid() {
    final validOptions = SampleSizeCatalog.optionsFor(
      factorCount: experimentStructure.factorCount,
      riskLevel: riskLevel,
    );
    if (validOptions.contains(sampleSizeOption)) {
      // Re-bind to the catalog instance so the user-selected option always
      // carries the catalog's `detectableDifferences` data (a fresh-from-JSON
      // option may have arrived here with an empty map).
      sampleSizeOption = validOptions.firstWhere(
        (option) => option == sampleSizeOption,
      );
      return;
    }

    // Preserve the user's chosen totalSamples across structure or
    // risk-level changes when possible; otherwise fall back to the first
    // available option for the new (structure, riskLevel) pair.
    sampleSizeOption = validOptions.firstWhere(
      (option) => option.totalSamples == sampleSizeOption.totalSamples,
      orElse: () => validOptions.first,
    );
  }

  static List<FactorDefinition> _factorDefinitionsFromJson(Object? value) {
    if (value is! List) return const [];

    return value.whereType<Map>().map((item) {
      return FactorDefinition.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  static List<FactorDefinition> _normalizedFactorDefinitions(
    ExperimentStructure structure,
    List<FactorDefinition>? definitions,
  ) {
    return List.generate(
      structure.factorCount,
      (index) => index < (definitions?.length ?? 0)
          ? definitions![index]
          : const FactorDefinition(),
    );
  }
}
