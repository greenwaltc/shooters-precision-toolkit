// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

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
/// Identified by [numSets] + [setSize] + [family]. The total number of
/// samples is [totalSamples] = [numSets] * [setSize]:
///
/// * [setSize] is the cardinality of the Cartesian product of factor-state
///   combinations for the experiment (e.g. `2` for a 1-factor / 2-state
///   simple comparison, `2^N` for an N-factor / 2-state-per-factor
///   factorial design).
/// * [numSets] is the number of times that one full Cartesian-product set
///   is repeated. Allowed to be fractional (e.g. `1.5`) to support
///   fractional-factorial designs.
///
/// To expose new options in the UI, edit the per-structure lists in
/// [SampleSizeCatalog] — no other changes to this class are required.
@immutable
class SampleSizeOption {
  const SampleSizeOption({
    required this.numSets,
    required this.setSize,
    required this.family,
  });

  /// Number of times the full Cartesian-product set of factor-state
  /// combinations is repeated.
  final num numSets;

  /// Cardinality of one full Cartesian-product set of factor-state
  /// combinations.
  final int setSize;

  final SampleSizeFamily family;

  /// Total number of individual samples — `numSets * setSize`, rounded to
  /// the nearest integer to absorb fractional-factorial replications.
  int get totalSamples => (numSets * setSize).round();

  /// Number of groups in the design — one per Cartesian-product cell.
  int get groupCount => setSize;

  /// Number of replicate ranges per group.
  num get rangesPerGroup => numSets;

  /// Display label, e.g. `"16 total samples in 4 groups of 4 ranges each"`.
  String get label {
    final ranges = _formatSampleValue(rangesPerGroup);
    return '$totalSamples total samples in $setSize groups of '
        '$ranges ranges each';
  }

  factory SampleSizeOption.fromJson(Map<String, dynamic> json) {
    return SampleSizeOption(
      numSets: (json['numSets'] as num?) ?? 0,
      setSize: (json['setSize'] as int?) ?? 0,
      family: SampleSizeFamily.fromName(json['family'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numSets': numSets,
      'setSize': setSize,
      'family': family.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SampleSizeOption &&
        other.numSets == numSets &&
        other.setSize == setSize &&
        other.family == family;
  }

  @override
  int get hashCode => Object.hash(numSets, setSize, family);

  static String _formatSampleValue(num value) {
    final asDouble = value.toDouble();
    return asDouble == asDouble.roundToDouble()
        ? asDouble.round().toString()
        : asDouble.toStringAsFixed(1);
  }
}

/// Source of truth for which [SampleSizeOption]s appear in the UI for a
/// given [ExperimentStructure].
///
/// One list per structure, since `setSize = 2^factorCount` differs by
/// factor count for factorial designs. Each list preserves the canonical
/// `totalSamples` levels — `8 / 14 / 56` for simple comparisons and
/// `16 / 24 / 48` for every factorial structure — by adapting `numSets`
/// to the structure-specific `setSize`.
///
/// To add or remove options, edit the lists below — no other changes to
/// the model layer are required.
class SampleSizeCatalog {
  const SampleSizeCatalog._();

  /// Per-structure available options.
  static const Map<ExperimentStructure, List<SampleSizeOption>> _byStructure = {
    ExperimentStructure.simpleABComparison: [
      // totalSamples: 8, 14, 56 — 1 factor / 2 states, setSize = 2.
      SampleSizeOption(
        numSets: 4,
        setSize: 2,
        family: SampleSizeFamily.simpleComparison,
      ),
      SampleSizeOption(
        numSets: 7,
        setSize: 2,
        family: SampleSizeFamily.simpleComparison,
      ),
      SampleSizeOption(
        numSets: 28,
        setSize: 2,
        family: SampleSizeFamily.simpleComparison,
      ),
    ],
    ExperimentStructure.twoFactors: [
      // totalSamples: 16, 24, 48 — 2 factors, setSize = 4.
      SampleSizeOption(
        numSets: 4,
        setSize: 4,
        family: SampleSizeFamily.factorial,
      ),
      SampleSizeOption(
        numSets: 6,
        setSize: 4,
        family: SampleSizeFamily.factorial,
      ),
      SampleSizeOption(
        numSets: 12,
        setSize: 4,
        family: SampleSizeFamily.factorial,
      ),
    ],
    ExperimentStructure.threeFactors: [
      // totalSamples: 16, 24, 48 — 3 factors, setSize = 8.
      SampleSizeOption(
        numSets: 2,
        setSize: 8,
        family: SampleSizeFamily.factorial,
      ),
      SampleSizeOption(
        numSets: 3,
        setSize: 8,
        family: SampleSizeFamily.factorial,
      ),
      SampleSizeOption(
        numSets: 6,
        setSize: 8,
        family: SampleSizeFamily.factorial,
      ),
    ],
    ExperimentStructure.fourFactors: [
      // totalSamples: 16, 24, 48 — 4 factors, setSize = 16.
      // numSets: 1.5 represents a half-fraction replication for the
      // 24-sample design.
      SampleSizeOption(
        numSets: 1,
        setSize: 16,
        family: SampleSizeFamily.factorial,
      ),
      SampleSizeOption(
        numSets: 1.5,
        setSize: 16,
        family: SampleSizeFamily.factorial,
      ),
      SampleSizeOption(
        numSets: 3,
        setSize: 16,
        family: SampleSizeFamily.factorial,
      ),
    ],
  };

  /// Returns the available [SampleSizeOption]s for [structure].
  static List<SampleSizeOption> optionsFor(ExperimentStructure structure) {
    return _byStructure[structure] ?? const [];
  }

  /// Resolves a persisted [SampleSizeOption] back to one of the catalog
  /// entries for [structure].
  ///
  /// Tries an exact-shape match first, then falls back to a totalSamples
  /// match (so saved projects keep the user's selection across catalog
  /// edits or factor-count changes).
  static SampleSizeOption resolveFromJson(
    Map<String, dynamic>? json,
    ExperimentStructure structure,
  ) {
    final options = optionsFor(structure);
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
           SampleSizeCatalog.optionsFor(experimentStructure).first,
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

    return ProjectFormModel(
      projectTitle: json['projectTitle'] as String? ?? '',
      experimentStructure: structure,
      riskLevel: RiskLevel.fromName(json['riskLevel'] as String?),
      sampleSizeOption: SampleSizeCatalog.resolveFromJson(
        sampleSizeJson,
        structure,
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
    final validOptions = SampleSizeCatalog.optionsFor(experimentStructure);
    if (validOptions.contains(sampleSizeOption)) return;

    // Preserve the user's chosen totalSamples across factor-count changes
    // when possible; otherwise fall back to the first available option.
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
