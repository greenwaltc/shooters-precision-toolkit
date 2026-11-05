import 'package:bramwells_precision_test_kit/features/experiments/data/firestore_project_repository.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository failures expose no backend messages or credentials', () {
    for (final entry in {
      'permission-denied': FailureKind.denied,
      'unauthenticated': FailureKind.unauthenticated,
      'unavailable': FailureKind.unavailable,
      'invalid-argument': FailureKind.invalidInput,
      'unknown token=private': FailureKind.unknown,
    }.entries) {
      final failure = mapProjectFailure(entry.key);
      expect(failure.kind, entry.value);
      expect(failure.toString(), isNot(contains('private')));
    }
  });
}
