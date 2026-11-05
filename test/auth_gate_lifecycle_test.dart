import 'package:bramwells_precision_test_kit/auth/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

class _CountingAuth extends FakeAuth {
  _CountingAuth({super.initialUser});

  int streamsCreated = 0;

  @override
  Stream<User?> userChanges() {
    streamsCreated++;
    return super.userChanges();
  }
}

void main() {
  testWidgets(
    'auth rebuilds retain the stream and replacing auth replaces it',
    (tester) async {
      final first = _CountingAuth();
      final second = _CountingAuth(
        initialUser: FakeAuthUser(uid: 'new', email: 'new@example.test'),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await first.dispose();
        await second.dispose();
      });
      Widget application(_CountingAuth auth) => MaterialApp(
        home: AuthGate(
          auth: auth,
          signedOutBuilder: (_) => const Text('Signed out'),
          verifyEmailBuilder: (_) => const Text('Verify'),
          signedInBuilder: (_, _) => const Text('Signed in'),
        ),
      );
      await tester.pumpWidget(application(first));
      await tester.pumpAndSettle();
      await tester.pumpWidget(application(first));
      await tester.pumpAndSettle();
      expect(first.streamsCreated, 1);
      expect(find.text('Signed out'), findsOneWidget);
      await tester.pumpWidget(application(second));
      await tester.pumpAndSettle();
      expect(second.streamsCreated, 1);
      expect(find.text('Verify'), findsOneWidget);
    },
  );
}
