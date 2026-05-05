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

@immutable
class SampleSizeOption {
  const SampleSizeOption({
    required this.totalSamples,
    required this.family,
    required this.detectableDifferences,
  });

  final int totalSamples;
  final SampleSizeFamily family;
  final List<String> detectableDifferences;

  static const simpleEight = SampleSizeOption(
    totalSamples: 8,
    family: SampleSizeFamily.simpleComparison,
    detectableDifferences: ['±45%', '±52%', '±66%'],
  );

  static const simpleFourteen = SampleSizeOption(
    totalSamples: 14,
    family: SampleSizeFamily.simpleComparison,
    detectableDifferences: ['±34%', '±40%', '±52%'],
  );

  static const simpleFiftySix = SampleSizeOption(
    totalSamples: 56,
    family: SampleSizeFamily.simpleComparison,
    detectableDifferences: ['±17%', '±20%', '±26%'],
  );

  static const factorialSixteen = SampleSizeOption(
    totalSamples: 16,
    family: SampleSizeFamily.factorial,
    detectableDifferences: ['±31%', '±37%', '±48%'],
  );

  static const factorialTwentyFour = SampleSizeOption(
    totalSamples: 24,
    family: SampleSizeFamily.factorial,
    detectableDifferences: ['±25%', '±30%', '±40%'],
  );

  static const factorialFortyEight = SampleSizeOption(
    totalSamples: 48,
    family: SampleSizeFamily.factorial,
    detectableDifferences: ['±18%', '±21%', '±28%'],
  );

  static const simpleOptions = [simpleEight, simpleFourteen, simpleFiftySix];

  static const factorialOptions = [
    factorialSixteen,
    factorialTwentyFour,
    factorialFortyEight,
  ];

  static List<SampleSizeOption> optionsFor(ExperimentStructure structure) {
    return structure.usesFactorialSamplePlan ? factorialOptions : simpleOptions;
  }

  static SampleSizeOption fromJson(
    Map<String, dynamic>? json,
    ExperimentStructure structure,
  ) {
    if (json == null) return optionsFor(structure).first;

    final family = SampleSizeFamily.fromName(json['family'] as String?);
    final totalSamples = json['totalSamples'] as int?;
    final options = optionsFor(structure);

    return options.firstWhere(
      (option) =>
          option.family == family && option.totalSamples == totalSamples,
      orElse: () => options.first,
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

  String detectableDifferenceFor(RiskLevel riskLevel) {
    return detectableDifferences[RiskLevel.values.indexOf(riskLevel)];
  }

  String labelFor(ExperimentStructure structure) {
    final groupCount = groupCountFor(structure);
    final rangesPerGroup = _formatSampleValue(rangesPerGroupFor(structure));

    return '$totalSamples total samples in $groupCount groups of '
        '$rangesPerGroup ranges each';
  }

  static String _formatSampleValue(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
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
           SampleSizeOption.optionsFor(experimentStructure).first,
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
      sampleSizeOption: SampleSizeOption.fromJson(sampleSizeJson, structure),
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
    final validOptions = SampleSizeOption.optionsFor(experimentStructure);
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
