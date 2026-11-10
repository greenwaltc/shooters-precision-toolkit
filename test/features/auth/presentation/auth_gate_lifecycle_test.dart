import 'package:bramwells_precision_test_kit/features/auth/api/auth_repository.dart';
import 'package:bramwells_precision_test_kit/features/auth/data/auth_service.dart';
import 'package:bramwells_precision_test_kit/features/auth/presentation/auth_gate.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:clock/clock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth.dart';
import '../../../support/test_configuration.dart';

class _CountingAuth extends FakeAuth {
  _CountingAuth({super.initialUser});

  int streamsCreated = 0;

  @override
  Stream<User?> userChanges() {
    streamsCreated++;
    return super.userChanges();
  }
}

class _ExpiredUser extends FakeAuthUser {
  _ExpiredUser()
    : super(uid: 'expired', email: 'old@example.test', verified: true);

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw FirebaseAuthException(
      code: 'user-token-expired',
      message: 'private server payload',
    );
  }
}

void main() {
  testWidgets('an expired verified session must sign in again', (tester) async {
    final fake = FakeAuth(initialUser: _ExpiredUser());
    addTearDown(() async {
      await pumpConfiguredWidget(tester, const SizedBox.shrink());
      await fake.dispose();
    });
    final auth = AuthService(
      fake,
      sessions: fake.sessions,
      returnOrigin: Uri.parse('http://127.0.0.1:7357'),
      emailCooldown: const Duration(seconds: 60),
      clock: const Clock(),
    );
    var privateBuilds = 0;
    await pumpConfiguredWidget(
      tester,
      AuthGate(
        auth: auth,
        signedOutBuilder: (_) => const MaterialApp(home: Text('Signed out')),
        verifyEmailBuilder: (_) => const MaterialApp(home: Text('Verify')),
        signedInBuilder: (_, _) {
          privateBuilds++;
          return const MaterialApp(home: Text('Private workspace'));
        },
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(
      find.text(AppCopy.english.unableToConfirmYourSession),
      findsOneWidget,
    );
    expect(find.text('private server payload'), findsNothing);
    await tester.tap(find.text(AppCopy.english.signOut));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('Signed out'), findsOneWidget);
    expect(privateBuilds, 0);
  });

  testWidgets(
    'auth rebuilds retain the stream and replacing auth replaces it',
    (tester) async {
      final first = _CountingAuth();
      final second = _CountingAuth(
        initialUser: FakeAuthUser(uid: 'new', email: 'new@example.test'),
      );
      addTearDown(() async {
        await pumpConfiguredWidget(tester, const SizedBox.shrink());
        await first.dispose();
        await second.dispose();
      });
      Widget application(AuthRepository auth) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthGate(
          auth: auth,
          signedOutBuilder: (_) => const Text('Signed out'),
          verifyEmailBuilder: (_) => const Text('Verify'),
          signedInBuilder: (_, _) => const Text('Signed in'),
        ),
      );
      final firstAdapter = AuthService(
        first,
        sessions: first.sessions,
        returnOrigin: Uri.parse('http://127.0.0.1:7357'),
        emailCooldown: const Duration(seconds: 60),
        clock: const Clock(),
      );
      final secondAdapter = AuthService(
        second,
        sessions: second.sessions,
        returnOrigin: Uri.parse('http://127.0.0.1:7357'),
        emailCooldown: const Duration(seconds: 60),
        clock: const Clock(),
      );
      await pumpConfiguredWidget(tester, application(firstAdapter));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await pumpConfiguredWidget(tester, application(firstAdapter));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(first.streamsCreated, 1);
      expect(find.text('Signed out'), findsOneWidget);
      await pumpConfiguredWidget(tester, application(secondAdapter));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(second.streamsCreated, 1);
      expect(find.text('Verify'), findsOneWidget);
    },
  );
}
