import 'dart:convert';

import 'package:bramwells_precision_test_kit/features/contact/api/contact_sender.dart';
import 'package:bramwells_precision_test_kit/features/contact/data/web3forms_contact_sender.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/app_failure.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/diagnostics.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/json_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final message = ContactMessage(
    name: ' Example ',
    email: ' visitor@example.test ',
    message: ' A test message. ',
  );

  test('posts only the intended fields to the Web3Forms endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.https('api.web3forms.com', '/submit'));
      expect(request.followRedirects, isFalse);
      expect(request.headers['Content-Type'], 'application/json');
      expect(decodeJsonObject(request.body), {
        'access_key': 'test-form-key',
        'name': 'Example',
        'email': 'visitor@example.test',
        'message': 'A test message.',
      });
      return http.Response(jsonEncode({'success': true}), 200);
    });
    addTearDown(client.close);
    await Web3FormsContactSender(
      client: client,
      accessKey: 'test-form-key',
      diagnostics: const NoopDiagnostics(),
    ).send(message);
  });

  for (final (status, body) in [
    (200, '{"success":false,"message":"private response"}'),
    (200, 'unexpected HTML'),
    (429, '{"success":false}'),
  ]) {
    test(
      'treats HTTP $status with an unsuccessful payload as failure',
      () async {
        final client = MockClient((_) async => http.Response(body, status));
        addTearDown(client.close);
        final sender = Web3FormsContactSender(
          client: client,
          accessKey: 'test-form-key',
          diagnostics: const NoopDiagnostics(),
        );
        await expectLater(
          sender.send(message),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.kind,
              'kind',
              FailureKind.unavailable,
            ),
          ),
        );
      },
    );
  }
}
