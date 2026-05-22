// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../sample_size_catalog.dart';

enum ExperimentStructure {
  simpleABComparison(
    label: 'Test How One Factor (two states) Influences Precision',
    factorCount: 1,
    usesFactorialSamplePlan: false,
  ),
  twoFactors(label: 'Test How Two Factors Influence Precision', factorCount: 2),
  threeFactors(label: 'Test How Three Factors Influence Precision', factorCount: 3),
  fourFactors(label: 'Test How Four Factors Influence Precision', factorCount: 4);

  const ExperimentStructure({
    required this.label,
    required this.factorCount,
    this.usesFactorialSamplePlan = true,
  });

  final String label;
  final int factorCount;
  final bool usesFactorialSamplePlan;

  static ExperimentStructure fromName(String? name) {
    return ExperimentStructure.values.firstWhere(
      (structure) => structure.name == name,
      orElse: () => ExperimentStructure.simpleABComparison,
    );
  }
}

enum RiskLevel {
  tenPercent('10%'),
  fivePercent('5%'),
  onePercent('1%');

  const RiskLevel(this.label);

  final String label;

  static RiskLevel fromName(String? name) {
    return RiskLevel.values.firstWhere(
      (riskLevel) => riskLevel.name == name,
      orElse: () => RiskLevel.tenPercent,
    );
  }
}

enum SampleSizeFamily {
  simpleComparison,
  factorial;

  static SampleSizeFamily fromName(String? name) {
    return SampleSizeFamily.values.firstWhere(
      (family) => family.name == name,
      orElse: () => SampleSizeFamily.simpleComparison,
    );
  }
}

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

  factory FactorDefinition.fromJson(Map<String, dynamic> json) {
    return FactorDefinition(
      name: json['name'] as String? ?? '',
      firstState: json['firstState'] as String? ?? '',
      secondState: json['secondState'] as String? ?? '',
    );
  }

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

  /// Display label, e.g. `"16 total samples in 4 groups of 4 ranges each"`.
  String get label {
    final ranges = _formatSampleValue(rangesPerGroup);
    return '$totalSamples total samples in $ranges groups of '
        '$groupSize ranges each';
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
    final numFactors = numFactorsFromJson ??
        (persistedGroupSize > 0 ? _numFactorsForGroupSize(persistedGroupSize) : 0);

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

  List<FactorDefinition> get factorDefinitions {
    return List.unmodifiable(_factorDefinitions);
  }

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

  void setProjectTitle(String title) {
    if (projectTitle == title) return;

    projectTitle = title;
    notifyListeners();
  }

  void setExperimentStructure(ExperimentStructure structure) {
    if (experimentStructure == structure) return;

    experimentStructure = structure;
    _resizeFactorDefinitions(structure.factorCount);
    _ensureSampleSizeOptionIsValid();
    notifyListeners();
  }

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

  void setRiskLevel(RiskLevel level) {
    if (riskLevel == level) return;

    riskLevel = level;
    _ensureSampleSizeOptionIsValid();
    notifyListeners();
  }

  void setSampleSizeOption(SampleSizeOption option) {
    if (sampleSizeOption == option) return;

    sampleSizeOption = option;
    notifyListeners();
  }

  void setImputeMissingData(bool shouldImpute) {
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
