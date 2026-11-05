import 'dart:ui' show PlatformDispatcher;

import 'package:bramwells_precision_test_kit/app/observability/error_boundary.dart';
import 'package:bramwells_precision_test_kit/app/observability/safe_diagnostics.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/json_object.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'framework and async errors report safely and hooks are restored',
    (tester) async {
      final dispatcher = PlatformDispatcher.instance;
      final framework = FlutterError.onError;
      final platform = dispatcher.onError;
      final errorWidget = ErrorWidget.builder;
      final output = <String>[];
      final diagnostics = SafeDiagnostics(
        configuration: null,
        write: output.add,
      );
      final failure = StateError('private data');
      final details = FlutterErrorDetails(exception: failure);
      final restore = installErrorBoundary(diagnostics, dispatcher: dispatcher);
      late final Widget fallback;
      try {
        FlutterError.onError!(details);
        expect(dispatcher.onError!(failure, StackTrace.empty), isTrue);
        fallback = ErrorWidget.builder(details);
      } finally {
        restore();
      }

      expect(FlutterError.onError, same(framework));
      expect(dispatcher.onError, same(platform));
      expect(ErrorWidget.builder, same(errorWidget));
      expect(output.map((line) => decodeJsonObject(line)['event']), [
        'frameworkError',
        'uncaughtAsyncError',
      ]);
      expect(output.join(), isNot(contains('private data')));
      await tester.pumpWidget(fallback);
      expect(find.text(AppCopy.english.unexpectedAppError), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
