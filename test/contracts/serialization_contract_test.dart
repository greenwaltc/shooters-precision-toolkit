import 'dart:convert';
import 'dart:math';

import 'package:bramwells_precision_test_kit/features/experiments/presentation/saved_project.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/json_object.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_configuration.dart';

void main() {
  test('JSON boundary rejects non-objects and malformed field types', () {
    for (final source in ['null', '[]', '42', '"object"']) {
      expect(() => decodeJsonObject(source), throwsFormatException);
    }
    expect(() => jsonObject({1: 'not a string key'}), throwsFormatException);
    for (final entry in <String, Object?>{
      'projectTitle': 123,
      'experimentStructure': false,
      'riskLevel': [],
      'sampleSizeOption': 'invalid',
      'factorDefinitions': [false],
      'imputeMissingData': 'true',
    }.entries) {
      expect(
        () => ProjectFormModel.fromJson({entry.key: entry.value}),
        throwsFormatException,
        reason: entry.key,
      );
    }
    expect(
      () => FactorDefinition.fromJson({'name': 12}),
      throwsFormatException,
    );
    expect(
      () => SampleSizeOption.fromJson({'numSets': 'two'}),
      throwsFormatException,
    );
  });

  test('saved-project parsing validates mutable editing payloads', () {
    for (final entry in <String, Object?>{
      'id': false,
      'formModel': [],
      'matrixState': [],
      'setupComplete': 1,
      'randomizeOrder': 'yes',
      'randomizeSequence': [1.5],
    }.entries) {
      expect(
        () => SavedProject.fromJson({entry.key: entry.value}),
        throwsFormatException,
        reason: entry.key,
      );
    }
    for (final sequence in [
      [-1],
      ['0'],
    ]) {
      expect(
        () => SavedProject.fromJson({'randomizeSequence': sequence}),
        throwsFormatException,
      );
    }
    final model = ProjectFormModel();
    final now = DateTime.utc(2026);
    final project = SavedProject(
      id: 'p',
      createdAt: now,
      updatedAt: now,
      formModel: model,
      randomizeSequence: [1, 0],
      matrixState: {'range_0': '1.5'},
    );
    expect(
      SavedProject.fromJson(
        decodeJsonObject(jsonEncode(project.toJson())),
      ).toJson(),
      project.toJson(),
    );
  });

  test('app dependencies are validated outside assertions', () {
    expect(
      () => MyApp(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        config: testConfig(),
        random: Random(4729),
      ),
      throwsArgumentError,
    );
  });
}
