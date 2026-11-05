import 'dart:convert';
import 'dart:typed_data';

import 'package:bramwells_precision_test_kit/features/experiments/api/project_snapshot.dart';
import 'package:bramwells_precision_test_kit/features/experiments/api/test_design.dart';
import 'package:bramwells_precision_test_kit/features/experiments/domain/project_file_codec.dart';
import 'package:bramwells_precision_test_kit/features/experiments/domain/sample_size_catalog.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/behavior_policy.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/json_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProjectSnapshot project;
  setUp(() {
    project = ProjectSnapshot(
      id: 'original',
      createdAt: DateTime.utc(2026, 5, 3),
      updatedAt: DateTime.utc(2026, 5, 4),
      formModel: TestDesignSnapshot(
        projectTitle: 'Précision study',
        experimentStructure: ExperimentStructure.twoFactors,
        riskLevel: RiskLevel.fivePercent,
        sampleSizeOption: SampleSizeCatalog.optionsFor(
          factorCount: 2,
          riskLevel: RiskLevel.fivePercent,
        ).first,
        factorDefinitions: const [
          FactorDefinition(name: 'Primer', firstState: 'A', secondState: 'B'),
          FactorDefinition(
            name: 'Charge',
            firstState: 'Low',
            secondState: 'High',
          ),
          FactorDefinition(),
          FactorDefinition(),
        ],
        imputeMissingData: true,
      ),
      setupComplete: true,
      randomizeOrder: true,
      randomizeSequence: List.generate(16, (index) => 15 - index),
      matrixState: const {
        'range_0': '1.23456789',
        'range_1': 2.5,
        'range_2': null,
      },
    );
  });

  test(
    'round trips the saved project fields and an independent file version',
    () {
      final bytes = ProjectFileCodec.encode(project);
      final json = decodeJsonObject(utf8.decode(bytes));
      expect(json.remove('schemaVersion'), ProjectFileCodec.supportedVersion);
      expect(json, project.toJson());
      expect(ProjectFileCodec.decode(bytes).toJson(), project.toJson());
    },
  );

  test('reports an unsupported version and rejects a missing version', () {
    final version = ProjectFileCodec.supportedVersion + 1;
    expect(
      () => ProjectFileCodec.decode(
        _bytes({...project.toJson(), 'schemaVersion': version}),
      ),
      throwsA(
        isA<UnsupportedProjectFileVersion>().having(
          (error) => error.version,
          'version',
          version,
        ),
      ),
    );
    expect(
      () => ProjectFileCodec.decode(_bytes(project.toJson())),
      throwsFormatException,
    );
  });

  test('rejects invalid UTF-8, malformed JSON, and oversized input', () {
    for (final bytes in [
      Uint8List.fromList([0xff]),
      utf8.encode('{'),
      Uint8List(BehaviorPolicy.maxProjectFileBytes + 1),
    ]) {
      expect(() => ProjectFileCodec.decode(bytes), throwsFormatException);
    }
  });

  test('rejects invalid fields instead of silently normalizing them', () {
    final form = project.formModel.toJson();
    final sample = jsonObject(form['sampleSizeOption']);
    for (final override in <Map<String, Object?>>[
      {'setupComplete': 'true'},
      {'updatedAt': 'tomorrow'},
      {'revision': 1},
      {
        'randomizeSequence': [0, 0],
      },
      {
        'matrixState': {'range_0': <Object?>[]},
      },
      {
        'matrixState': {'range_0': 'unmeasured'},
      },
      {
        'matrixState': {'row_0': 5},
      },
      {
        'formModel': {...form, 'experimentStructure': 'unknown'},
      },
      {
        'formModel': {...form, 'factorDefinitions': <Object?>[]},
      },
      {
        'formModel': {
          ...form,
          'sampleSizeOption': {...sample, 'setSize': 8},
        },
      },
      {
        'formModel': {
          ...form,
          'sampleSizeOption': {...sample, 'numSets': 99},
        },
      },
    ]) {
      final invalid = _bytes({
        ...project.toJson(),
        ...override,
        'schemaVersion': ProjectFileCodec.supportedVersion,
      });
      expect(
        () => ProjectFileCodec.decode(invalid),
        throwsFormatException,
        reason: '$override',
      );
    }
    final missing = project.toJson()
      ..remove('randomizeSequence')
      ..['schemaVersion'] = ProjectFileCodec.supportedVersion;
    expect(
      () => ProjectFileCodec.decode(_bytes(missing)),
      throwsFormatException,
    );
  });
}

Uint8List _bytes(Map<String, Object?> json) => utf8.encode(jsonEncode(json));
