import 'package:flutter_test/flutter_test.dart';
import 'package:bramwells_precision_test_kit/model/project_form_model.dart';

void main() {
  group('ProjectFormModel factor persistence', () {
    test('stored definitions survive structure count changes', () {
      final model = ProjectFormModel();

      model.setExperimentStructure(ExperimentStructure.threeFactors);
      model.setFactorDefinition(
        index: 0,
        name: 'Factor 1',
        firstState: 'Low',
        secondState: 'High',
      );
      model.setFactorDefinition(
        index: 1,
        name: 'Factor 2',
        firstState: 'Off',
        secondState: 'On',
      );
      model.setFactorDefinition(
        index: 2,
        name: 'Factor 3',
        firstState: 'A',
        secondState: 'B',
      );

      model.setExperimentStructure(ExperimentStructure.simpleABComparison);
      expect(model.factorDefinitions, hasLength(1));
      expect(model.storedFactorDefinitionAt(1).name, 'Factor 2');
      expect(model.storedFactorDefinitionAt(2).firstState, 'A');

      model.setExperimentStructure(ExperimentStructure.fourFactors);
      expect(model.storedFactorDefinitionAt(0).name, 'Factor 1');
      expect(model.storedFactorDefinitionAt(1).name, 'Factor 2');
      expect(model.storedFactorDefinitionAt(2).name, 'Factor 3');
      expect(model.storedFactorDefinitionAt(3).name, isEmpty);
    });

    test('setup validation only checks active factors', () {
      final model = ProjectFormModel(
        projectTitle: 'Test Project',
      );
      model.setFactorDefinition(
        index: 0,
        name: 'Only Factor',
        firstState: 'Low',
        secondState: 'High',
      );

      expect(model.isSetupValid, isTrue);
    });

    test('round-trips all stored definitions through JSON', () {
      final model = ProjectFormModel(
        experimentStructure: ExperimentStructure.simpleABComparison,
      );
      model.setFactorDefinition(
        index: 1,
        name: 'Hidden Factor',
        firstState: 'Left',
        secondState: 'Right',
      );

      final restored = ProjectFormModel.fromJson(model.toJson());

      expect(
        restored.storedFactorDefinitionAt(1).name,
        'Hidden Factor',
      );
      expect(restored.factorDefinitions, hasLength(1));
    });
  });
}
