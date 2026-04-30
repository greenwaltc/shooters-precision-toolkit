import 'package:flutter/material.dart';

enum ExperimentStructure {
  simpleABComparison(
    label: 'Text How One Factor (two states) Influence A',
    factorCount: 1,
    usesFactorialSamplePlan: false,
  ),
  twoFactors(label: 'Test How Two Factors Influence A', factorCount: 2),
  threeFactors(label: 'Test How Three Factors Influence A', factorCount: 3),
  fourFactors(label: 'Test How Four Factors Influence A', factorCount: 4);

  const ExperimentStructure({
    required this.label,
    required this.factorCount,
    this.usesFactorialSamplePlan = true,
  });

  final String label;
  final int factorCount;
  final bool usesFactorialSamplePlan;
}

enum RiskLevel {
  tenPercent('10%'),
  fivePercent('5%'),
  onePercent('1%');

  const RiskLevel(this.label);

  final String label;
}

enum SampleSizeFamily { simpleComparison, factorial }

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

  FactorDefinition copyWith({
    String? name,
    String? firstState,
    String? secondState,
  }) {
    return FactorDefinition(
      name: name ?? this.name,
      firstState: firstState ?? this.firstState,
      secondState: secondState ?? this.secondState,
    );
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
    detectableDifferences: ['+-45%', '+-52%', '+-66%'],
  );

  static const simpleFourteen = SampleSizeOption(
    totalSamples: 14,
    family: SampleSizeFamily.simpleComparison,
    detectableDifferences: ['+-34%', '+-40%', '+-52%'],
  );

  static const simpleFiftySix = SampleSizeOption(
    totalSamples: 56,
    family: SampleSizeFamily.simpleComparison,
    detectableDifferences: ['+-17%', '+-20%', '+-26%'],
  );

  static const factorialSixteen = SampleSizeOption(
    totalSamples: 16,
    family: SampleSizeFamily.factorial,
    detectableDifferences: ['+-31%', '+-37%', '+-48%'],
  );

  static const factorialTwentyFour = SampleSizeOption(
    totalSamples: 24,
    family: SampleSizeFamily.factorial,
    detectableDifferences: ['+-25%', '+-30%', '+-40%'],
  );

  static const factorialFortyEight = SampleSizeOption(
    totalSamples: 48,
    family: SampleSizeFamily.factorial,
    detectableDifferences: ['+-18%', '+-21%', '+-28%'],
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

  static String _formatSampleValue(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }
}

class ProjectFormModel extends ChangeNotifier {
  String projectTitle = '';
  ExperimentStructure experimentStructure =
      ExperimentStructure.simpleABComparison;
  RiskLevel riskLevel = RiskLevel.tenPercent;
  SampleSizeOption sampleSizeOption = SampleSizeOption.simpleEight;
  bool imputeMissingData = false;

  final List<FactorDefinition> _factorDefinitions = List.generate(
    ExperimentStructure.simpleABComparison.factorCount,
    (_) => const FactorDefinition(),
  );

  ProjectFormModel();

  List<FactorDefinition> get factorDefinitions {
    return List.unmodifiable(_factorDefinitions);
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
}
