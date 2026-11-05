import 'package:flutter/material.dart';

import '../../../../shared/foundation/json_object.dart';
import '../../../../shared/ui/product_configuration.dart';
import '../../api/test_design.dart';
import '../../domain/sample_size_catalog.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

export '../../api/test_design.dart'
    show
        ExperimentStructure,
        RiskLevel,
        SampleSizeFamily,
        FactorDefinition,
        SampleSizeOption;
export 'test_design_labels.dart'
    show ExperimentStructureLabels, RiskLevelLabels, SampleSizeLabels;

/// Mutable project setup state used by the form and downstream matrix.
class ProjectFormModel extends ChangeNotifier {
  /// Creates an editable design with defaults for a two-state comparison.
  ///
  /// If [sampleSizeOption] is omitted, the model selects the default for the
  /// chosen structure.
  ProjectFormModel({
    this.projectTitle = '',
    this.featureFlags = FeatureFlags.defaults,
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

  FeatureFlags featureFlags;
  String projectTitle;
  ExperimentStructure experimentStructure;
  RiskLevel riskLevel;
  SampleSizeOption sampleSizeOption;
  bool imputeMissingData;

  final List<FactorDefinition> _factorDefinitions;

  /// Rehydrates form state from persisted JSON.
  factory ProjectFormModel.fromJson(Map<String, Object?> json) {
    final structure = ExperimentStructure.fromName(
      optionalJsonValue<String>(json, 'experimentStructure'),
    );
    final sampleSizeValue = json['sampleSizeOption'];
    final sampleSizeJson = sampleSizeValue == null
        ? null
        : jsonObject(sampleSizeValue);

    final risk = RiskLevel.fromName(
      optionalJsonValue<String>(json, 'riskLevel'),
    );

    return ProjectFormModel(
      projectTitle: optionalJsonValue<String>(json, 'projectTitle') ?? '',
      experimentStructure: structure,
      riskLevel: risk,
      sampleSizeOption: SampleSizeCatalog.resolveFromJson(
        json: sampleSizeJson,
        factorCount: structure.factorCount,
        riskLevel: risk,
      ),
      factorDefinitions: _factorDefinitionsFromJson(json['factorDefinitions']),
      imputeMissingData:
          optionalJsonValue<bool>(json, 'imputeMissingData') ?? false,
    );
  }

  /// Maximum number of factor slots retained across structure changes.
  static const int maxFactorCount = 4;

  /// Immutable view of the active factor definitions for the current structure.
  List<FactorDefinition> get factorDefinitions {
    return List.unmodifiable(
      _factorDefinitions.take(experimentStructure.factorCount),
    );
  }

  /// Returns a stored factor definition by index, including inactive slots.
  FactorDefinition storedFactorDefinitionAt(int index) {
    if (index < 0 || index >= _factorDefinitions.length) {
      return const FactorDefinition();
    }

    return _factorDefinitions[index];
  }

  /// Whether the impute-missing-data capability is enabled for this app build.
  bool get canImputeMissingData =>
      featureFlags.isEnabled(FeatureFlag.imputeMissingData);

  /// Whether missing range cells should be filled with the grand mean.
  bool get shouldImputeMissingData => canImputeMissingData && imputeMissingData;

  /// Whether the form satisfies the same requirements enforced by submit
  /// validation on [ProjectForm].
  bool get isSetupValid {
    if (projectTitle.trim().isEmpty) {
      return false;
    }

    final normalizedFactorNames = <String>{};
    for (var index = 0; index < experimentStructure.factorCount; index++) {
      final factor = _factorDefinitions[index];
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
  Map<String, Object?> toJson() {
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
    if (projectTitle == title) {
      return;
    }

    projectTitle = title;
    notifyListeners();
  }

  /// Updates the experiment structure and resizes factor definitions.
  void setExperimentStructure(ExperimentStructure structure) {
    if (experimentStructure == structure) {
      return;
    }

    experimentStructure = structure;
    _ensureFactorDefinitionsCapacity();
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
    if (index < 0 || index >= _factorDefinitions.length) {
      return;
    }

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
    if (riskLevel == level) {
      return;
    }

    riskLevel = level;
    _ensureSampleSizeOptionIsValid();
    notifyListeners();
  }

  /// Updates the selected sample-size option.
  void setSampleSizeOption(SampleSizeOption option) {
    if (sampleSizeOption == option) {
      return;
    }

    sampleSizeOption = option;
    notifyListeners();
  }

  /// Enables or disables missing-data imputation when the feature is active.
  void setImputeMissingData(bool shouldImpute) {
    if (!canImputeMissingData) {
      shouldImpute = false;
    }
    if (imputeMissingData == shouldImpute) {
      return;
    }

    imputeMissingData = shouldImpute;
    notifyListeners();
  }

  void _ensureFactorDefinitionsCapacity() {
    while (_factorDefinitions.length < maxFactorCount) {
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
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?>) {
      throw const FormatException('Factor definitions must be a list.');
    }

    return value.map((item) {
      return FactorDefinition.fromJson(jsonObject(item));
    }).toList();
  }

  static List<FactorDefinition> _normalizedFactorDefinitions(
    ExperimentStructure structure,
    List<FactorDefinition>? definitions,
  ) {
    return List.generate(
      maxFactorCount,
      (index) => index < (definitions?.length ?? 0)
          ? definitions![index]
          : const FactorDefinition(),
    );
  }
}
