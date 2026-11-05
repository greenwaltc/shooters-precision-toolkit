import 'package:bramwells_precision_test_kit/features/auth/api/auth_repository.dart';
import 'package:bramwells_precision_test_kit/features/auth/data/auth_service.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vendor failures become safe actionable app categories', () {
    final cases = {
      'invalid-email': AuthFailureCode.invalidEmail,
      'weak-password': AuthFailureCode.passwordPolicy,
      'email-already-in-use': AuthFailureCode.accountExists,
      'invalid-credential': AuthFailureCode.invalidCredentials,
      'too-many-requests': AuthFailureCode.rateLimited,
      'network-request-failed': AuthFailureCode.unavailable,
      'user-token-expired': AuthFailureCode.expiredSession,
      'untrusted private text@example.test': AuthFailureCode.unknown,
    };
    for (final entry in cases.entries) {
      final failure = mapAuthFailure(entry.key);
      expect(failure.code, entry.value);
      expect(failure.toString(), isNot(contains('@')));
    }
    expect(mapAuthFailure('permission-denied').kind, FailureKind.unknown);
  });
}
