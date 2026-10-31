import 'package:bramwells_precision_test_kit/auth/auth_page.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/widgets/project_form_page.dart';
import 'package:bramwells_precision_test_kit/widgets/project_home_page.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

void main() {
  testWidgets(
    'unverified user stays gated until verification and token refresh',
    (tester) async {
      final user = FakeAuthUser(uid: 'alice', email: 'alice@example.test');
      final auth = FakeAuth(initialUser: user);
      await _pumpApp(tester, auth);
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.byType(ProjectHomePage), findsNothing);
      await _tap(tester, find.text('I have verified my email'));
      expect(find.textContaining('Not verified yet.'), findsOneWidget);
      expect(find.byType(ProjectHomePage), findsNothing);
      user.serverVerified = true;
      await _tap(tester, find.text('I have verified my email'));
      expect(user.forcedTokenRefreshes, 1);
      expect(find.byType(ProjectHomePage), findsOneWidget);
      expect(find.byType(AuthPage), findsNothing);
    },
  );

  testWidgets(
    'verified session opens workspace and logout removes private routes',
    (tester) async {
      final user = FakeAuthUser(
        uid: 'alice',
        email: 'alice@example.test',
        verified: true,
      );
      final auth = FakeAuth(initialUser: user);
      await _pumpApp(tester, auth);
      expect(find.byType(ProjectHomePage), findsOneWidget);
      expect(find.byType(AuthPage), findsNothing);
      await _tap(tester, find.widgetWithIcon(FilledButton, Icons.add));
      expect(find.byType(ProjectFormPage), findsOneWidget);
      final oldNavigator = Navigator.of(
        tester.element(find.byType(ProjectFormPage)),
      );
      await tester.enterText(find.byType(TextFormField).first, 'Private draft');
      // Leave the form's debounce pending: logout must flush this edit.
      await _tap(tester, find.byTooltip('Sign out'));
      expect(auth.currentUser, isNull);
      expect(oldNavigator.mounted, isFalse);
      expect(find.byType(AuthPage), findsOneWidget);
      expect(find.byType(ProjectFormPage), findsNothing);
      expect(find.byType(ProjectHomePage), findsNothing);
      final loginNavigator = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      expect(loginNavigator.canPop(), isFalse);
      await loginNavigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);

      await _signIn(tester, 'alice@example.test');
      expect(find.text('Private draft'), findsOneWidget);
      expect(find.byType(ProjectFormPage), findsNothing);
    },
  );

  testWidgets('account switching shows only the signed-in UID workspace', (
    tester,
  ) async {
    final alice = FakeAuthUser(
      uid: 'alice',
      email: 'alice@example.test',
      verified: true,
    );
    final bob = FakeAuthUser(
      uid: 'bob',
      email: 'bob@example.test',
      verified: true,
    );
    final auth = FakeAuth(initialUser: alice)..users[bob.email!] = bob;
    await _pumpApp(tester, auth);
    await _tap(tester, find.widgetWithIcon(FilledButton, Icons.add));
    await tester.enterText(find.byType(TextFormField).first, 'Alice project');
    await _tap(tester, find.byTooltip('Sign out'));
    await _signIn(tester, 'bob@example.test');
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('Alice project'), findsNothing);
    await _tap(tester, find.byTooltip('Sign out'));
    await _signIn(tester, 'alice@example.test');
    expect(find.text('Alice project'), findsOneWidget);
  });

  testWidgets(
    'verification email failure can be retried without registering again',
    (tester) async {
      var now = DateTime.utc(2026);
      await withClock(Clock(() => now), () async {
        final auth = FakeAuth()..newUserVerificationFailures = 2;
        await _pumpApp(tester, auth);
        await _tap(
          tester,
          find.widgetWithText(TextButton, 'Create an account'),
        );
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'alice@example.test');
        await tester.enterText(fields.at(1), 'Test-password-123!');
        await tester.enterText(fields.at(2), 'Test-password-123!');
        await _tap(tester, find.widgetWithText(FilledButton, 'Create account'));
        expect(find.text('Verify your email'), findsOneWidget);
        expect(auth.registrations, 1);
        final user = auth.currentUser!;
        expect(user.verificationRequests, 1); // Initial automatic email failed.
        await _tap(tester, find.text('Send verification email'));
        expect(
          find.text('Check your connection and try again.'),
          findsOneWidget,
        );
        expect(user.verificationRequests, 2);
        // Retry is available after the UI's sending cooldown, without a new account.
        now = now.add(const Duration(seconds: 61));
        await tester.pump(const Duration(seconds: 61));
        await tester.pumpAndSettle();
        await _tap(tester, find.text('Send verification email'));
        expect(find.text('Verification email requested.'), findsOneWidget);
        expect(user.verificationRequests, 3);
        expect(auth.registrations, 1);
        expect(auth.currentUser!.uid, user.uid);
      });
    },
  );

  for (final existingAccount in [true, false]) {
    testWidgets(
      'password reset has a generic confirmation, existing=$existingAccount',
      (tester) async {
        final auth = FakeAuth();
        const email = 'alice@example.test';
        if (existingAccount) {
          auth.users[email] = FakeAuthUser(uid: 'alice', email: email);
        }
        await _pumpApp(tester, auth);
        await tester.enterText(find.byType(TextFormField).first, email);
        await _tap(tester, find.text('Forgot password?'));
        expect(
          find.text(
            'If that address has an account, a reset email has been sent.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('user-not-found'), findsNothing);
        expect(auth.passwordResetRequests, [email]);
        expect(auth.currentUser, isNull);
      },
    );
  }
}

Future<void> _pumpApp(WidgetTester tester, FakeAuth auth) async {
  rootBundle.clear();
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await auth.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(FirebaseApplication(services: auth.services));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'Test-password-123!',
  );
  await _tap(tester, find.widgetWithText(FilledButton, 'Sign in'));
}
