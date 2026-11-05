import 'package:bramwells_precision_test_kit/features/experiments/api/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> document() => {
  'id': 'fixture',
  'createdAt': '2026-11-04T10:00:00-07:00',
  'updatedAt': '2026-11-04T17:00:00Z',
  'formModel': {
    'projectTitle': 'Fixture',
    'experimentStructure': 'simpleABComparison',
    'riskLevel': 'tenPercent',
    'sampleSizeOption': null,
    'factorDefinitions': [
      {'name': 'Primer', 'firstState': 'A', 'secondState': 'B'},
    ],
    'imputeMissingData': false,
  },
  'setupComplete': false,
  'randomizeOrder': true,
  'randomizeSequence': [1, 0],
  'matrixState': {'range_0': '1.25'},
};

void main() {
  test(
    'snapshot owns collections and canonicalizes instants without Flutter models',
    () {
      final json = document();
      final snapshot = ProjectSnapshot.fromJson(json);
      (json['matrixState']! as Map<String, Object?>)['range_0'] = '99';
      expect(snapshot.matrixState['range_0'], '1.25');
      expect(snapshot.createdAt, DateTime.utc(2026, 11, 4, 17));
      expect(snapshot.createdAt.isUtc, isTrue);
      expect(() => snapshot.matrixState.clear(), throwsUnsupportedError);
      expect(() => snapshot.randomizeSequence!.clear(), throwsUnsupportedError);
      expect(
        () => snapshot.formModel.factorDefinitions.clear(),
        throwsUnsupportedError,
      );
      final copy = snapshot.toJson();
      (copy['matrixState']! as Map<String, Object?>).clear();
      expect(snapshot.matrixState, isNotEmpty);
      expect(snapshot.freeze(), same(snapshot));
      expect(
        ProjectSnapshot.fromJson(snapshot.toJson()).toJson(),
        snapshot.toJson(),
      );
    },
  );
  test(
    'external identity, timestamp, row and measurement shapes are validated',
    () {
      for (final mutation in <Map<String, Object?>>[
        {'id': ''},
        {'id': 'a/b'},
        {'createdAt': 'invalid'},
        {
          'randomizeSequence': [-1],
        },
        {
          'randomizeSequence': ['0'],
        },
        {
          'matrixState': {'range_0': double.infinity},
        },
        {
          'matrixState': {
            'range_0': {'untrusted': 'nested'},
          },
        },
      ]) {
        expect(
          () => ProjectSnapshot.fromJson(document()..addAll(mutation)),
          throwsFormatException,
        );
      }
    },
  );
}
