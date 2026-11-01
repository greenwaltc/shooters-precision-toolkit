import 'dart:async';

import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:bramwells_precision_test_kit/firebase/firebase_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup shows loading then a safe error without mounting app', (
    tester,
  ) async {
    final initialization = Completer<FirebaseServices>();
    var mounted = false;
    await tester.pumpWidget(
      FirebaseStartup(
        initialize: () => initialization.future,
        applicationBuilder: (_) {
          mounted = true;
          return const SizedBox();
        },
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    initialization.completeError(StateError('private SDK details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to start the app'), findsOneWidget);
    expect(find.textContaining('private SDK details'), findsNothing);
    expect(mounted, isFalse);
  });

  testWidgets('synchronous configuration failures also show the error screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      FirebaseStartup(
        initialize: () => throw StateError('Missing APP_ENV'),
        applicationBuilder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to start the app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
