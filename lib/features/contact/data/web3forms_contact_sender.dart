import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/foundation/diagnostics.dart';
import '../../../shared/foundation/json_object.dart';
import '../api/contact_sender.dart';

/// A contact sender that submits messages to Web3Forms.
///
/// The request has a deadline. Rejected or unconfirmed submissions surface as
/// app failures, and diagnostic events omit the message and form key.
final class Web3FormsContactSender implements ContactSender {
  /// Creates a sender for the form identified by [accessKey].
  ///
  /// The caller owns [client] and is responsible for closing it.
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

  /// Confirms receipt only when the provider returns HTTP 200 and a JSON
  /// success flag. Bounds the response because the provider can echo the
  /// submitted fields.
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
