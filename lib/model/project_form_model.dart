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
/// Pure value object: identified by [totalSamples] + [family]. There are no
/// pre-baked "named" instances — to expose more options in the UI, edit the
/// list returned by [SampleSizeCatalog.optionsFor].
@immutable
class SampleSizeOption {
  const SampleSizeOption({required this.totalSamples, required this.family});

  final int totalSamples;
  final SampleSizeFamily family;

  factory SampleSizeOption.fromJson(Map<String, dynamic> json) {
    return SampleSizeOption(
      totalSamples: json['totalSamples'] as int? ?? 0,
      family: SampleSizeFamily.fromName(json['family'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {'totalSamples': totalSamples, 'family': family.name};
  }

  int groupCountFor(ExperimentStructure structure) {
    return structure.usesFactorialSamplePlan ? 1 << structure.factorCount : 2;
  }

  double rangesPerGroupFor(ExperimentStructure structure) {
    return totalSamples / groupCountFor(structure);
  }

  String labelFor(ExperimentStructure structure) {
    final groupCount = groupCountFor(structure);
    final rangesPerGroup = _formatSampleValue(rangesPerGroupFor(structure));

    return '$totalSamples total samples in $groupCount groups of '
        '$rangesPerGroup ranges each';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SampleSizeOption &&
        other.totalSamples == totalSamples &&
        other.family == family;
  }

  @override
  int get hashCode => Object.hash(totalSamples, family);

  static String _formatSampleValue(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }
}

/// Source of truth for which [SampleSizeOption]s appear in the UI for a
/// given [ExperimentStructure].
///
/// To add or remove options, edit the lists returned here — no other
/// changes to the model layer are required.
class SampleSizeCatalog {
  const SampleSizeCatalog._();

  /// Sample-size options for a simple A/B comparison experiment.
  static const List<SampleSizeOption> simpleOptions = [
    SampleSizeOption(totalSamples: 8, family: SampleSizeFamily.simpleComparison),
    SampleSizeOption(totalSamples: 14, family: SampleSizeFamily.simpleComparison),
    SampleSizeOption(totalSamples: 56, family: SampleSizeFamily.simpleComparison),
  ];

  /// Sample-size options for any factorial experiment (2/3/4-factor).
  static const List<SampleSizeOption> factorialOptions = [
    SampleSizeOption(totalSamples: 16, family: SampleSizeFamily.factorial),
    SampleSizeOption(totalSamples: 24, family: SampleSizeFamily.factorial),
    SampleSizeOption(totalSamples: 48, family: SampleSizeFamily.factorial),
  ];

  /// Returns the available [SampleSizeOption]s for [structure].
  static List<SampleSizeOption> optionsFor(ExperimentStructure structure) {
    return structure.usesFactorialSamplePlan ? factorialOptions : simpleOptions;
  }

  /// Resolves a persisted [SampleSizeOption] back to one of the catalog
  /// entries for [structure], falling back to the first option if no match
  /// is found.
  static SampleSizeOption resolveFromJson(
    Map<String, dynamic>? json,
    ExperimentStructure structure,
  ) {
    final options = optionsFor(structure);
    if (json == null) return options.first;

    final candidate = SampleSizeOption.fromJson(json);
    return options.firstWhere(
      (option) => option == candidate,
      orElse: () => options.first,
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
    if (!validOptions.contains(sampleSizeOption)) {
      sampleSizeOption = validOptions.first;
    }
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
