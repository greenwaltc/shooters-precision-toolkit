import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/foundation/diagnostics.dart';
import '../../../shared/foundation/json_object.dart';
import '../api/contact_sender.dart';

final class Web3FormsContactSender implements ContactSender {
  Web3FormsContactSender({
    required http.Client client,
    required String accessKey,
    required Diagnostics diagnostics,
  }) : _client = client,
       _accessKey = accessKey,
       _diagnostics = diagnostics;

  static final _endpoint = Uri.https('api.web3forms.com', '/submit');
  static const _maxResponseBytes = 64 * 1024;
  final http.Client _client;
  final String _accessKey;
  final Diagnostics _diagnostics;

  @override
  Future<void> send(ContactMessage message) async {
    if (!message.isValid) {
      throw const AppFailure(FailureKind.invalidInput);
    }
    final elapsed = Stopwatch()..start();
    final abort = Completer<void>();
    final request =
        http.AbortableRequest('POST', _endpoint, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({
            'access_key': _accessKey,
            'name': message.name,
            'email': message.email,
            'message': message.message,
          });

    try {
      await _submit(request).timeout(
        ContactPolicy.requestTimeout,
        onTimeout: () {
          abort.complete();
          throw const AppFailure(FailureKind.unavailable);
        },
      );
    } on Exception {
      const failure = AppFailure(FailureKind.unavailable);
      _diagnostics.record(
        DiagnosticEvent.contactSendFailed,
        error: failure,
        elapsed: elapsed.elapsed,
      );
      throw failure;
    }
  }

  Future<void> _submit(http.AbortableRequest request) async {
    final response = await _client.send(request);
    final body = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (body.length + chunk.length > _maxResponseBytes) {
        throw const AppFailure(FailureKind.invalidData);
      }
      body.add(chunk);
    }
    if (response.statusCode != 200 ||
        decodeJsonObject(utf8.decode(body.takeBytes()))['success'] != true) {
      throw const AppFailure(FailureKind.unavailable);
    }
  }
}
