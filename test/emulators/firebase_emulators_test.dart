@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:bramwells_precision_test_kit/auth/auth_page.dart';
import 'package:bramwells_precision_test_kit/auth/auth_service.dart';
import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/widgets/project_form_page.dart';
import 'package:bramwells_precision_test_kit/widgets/project_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

void main() {
  // Browser widget tests don't run the application's generated plugin registrant.
  final registrar = Registrar();
  FirebaseCoreWeb.registerWith(registrar);
  FirebaseAuthWeb.registerWith(registrar);
  FirebaseFirestoreWeb.registerWith(registrar);

  late FirebaseServices emulatorServices;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    // Fail before any account operation if this was invoked with cloud settings.
    expect(useEmulators, isTrue, reason: 'Run through task emulators:test.');
    emulatorServices = await bootstrapFirebase().timeout(
      const Duration(seconds: 30),
    );
    expect(emulatorServices.app.options.projectId, localFirebaseProjectId);
  });

  setUp(rootBundle.clear);

  testWidgets(
    'Flutter boots with local Auth and Firestore services',
    (tester) async {
      const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
      expect(useEmulators, isTrue, reason: 'Run through task emulators:test.');
      SharedPreferences.setMockInitialValues({});

      final services = await tester.runAsync(() async {
        final services = emulatorServices;
        // ignore: avoid_print
        print('Firebase initialized for the local demo project.');
        expect(services.app.options.projectId, localFirebaseProjectId);
        final email =
            'smoke-${DateTime.now().microsecondsSinceEpoch}@example.test';
        final credential = await services.auth
            .createUserWithEmailAndPassword(
              email: email,
              password: 'Local-test-password-123!',
            )
            .timeout(const Duration(seconds: 15));
        // ignore: avoid_print
        print('Auth emulator accepted the test account.');
        try {
          final token = await credential.user!.getIdToken();
          final claims =
              jsonDecode(
                    utf8.decode(
                      base64Url.decode(
                        base64Url.normalize(token!.split('.')[1]),
                      ),
                    ),
                  )
                  as Map<String, dynamic>;
          expect(claims['aud'], localFirebaseProjectId);

          // The checked-in bootstrap policy denies client access until migration
          // rules are implemented. A server rejection proves emulator connectivity.
          final document = services.db.doc('emulatorSmoke/connection');
          final permissionDenied = isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          );
          await expectLater(
            document.set({'smoke': true}).timeout(const Duration(seconds: 15)),
            throwsA(permissionDenied),
          );
          await expectLater(
            document
                .get(const GetOptions(source: Source.server))
                .timeout(const Duration(seconds: 15)),
            throwsA(permissionDenied),
          );
        } finally {
          await credential.user!.delete();
          await services.auth.signOut();
        }
        return services;
      });

      if (services == null) return; // runAsync already reports the failure.
      await tester.pumpWidget(FirebaseApplication(services: services));
      // Firebase's initial JS auth callback needs a real browser event turn;
      // pumpAndSettle only advances the widget test's fake clock.
      await tester.runAsync(() async {
        final user = await services.auth.userChanges().first.timeout(
          const Duration(seconds: 5),
        );
        expect(user, isNull);
      });
      await tester.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);
      expect(find.byType(ProjectHomePage), findsNothing);
      expect(find.textContaining('Unable to start the app'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'emulator verification opens workspace; logout removes private routes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final services = emulatorServices;
      final auth = AuthService(services.auth);
      final email =
          'gate-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'Local-test-password-123!';
      try {
        await tester.runAsync(
          () => auth
              .register(email, password)
              .timeout(const Duration(seconds: 15)),
        );
        expect(services.auth.currentUser!.emailVerified, isFalse);
        await tester.pumpWidget(FirebaseApplication(services: services));
        await _waitForAuth(tester, services, signedIn: true);
        expect(find.text('Verify your email'), findsOneWidget);
        expect(find.byType(ProjectHomePage), findsNothing);

        await tester.runAsync(() async {
          // Read only this uniquely named test account's local verification code.
          final response = await web.window
              .fetch(
                'http://127.0.0.1:9099/emulator/v1/projects/$localFirebaseProjectId/oobCodes'
                    .toJS,
              )
              .toDart
              .timeout(const Duration(seconds: 5));
          expect(response.ok, isTrue);
          final data = (await response.json().toDart).dartify() as Map;
          final codes = (data['oobCodes'] as List).cast<Map>().where(
            (code) =>
                code['email'] == email && code['requestType'] == 'VERIFY_EMAIL',
          );
          expect(codes, isNotEmpty);
          await services.auth.applyActionCode(codes.last['oobCode'] as String);
          expect(await auth.refreshVerification(), isTrue);
          final token = await services.auth.currentUser!.getIdTokenResult();
          expect(token.claims?['email_verified'], isTrue);
        });
        await _waitForAuth(tester, services, signedIn: true);
        expect(find.byType(ProjectHomePage), findsOneWidget);
        expect(find.byType(AuthPage), findsNothing);

        final create = find.widgetWithIcon(FilledButton, Icons.add);
        await tester.ensureVisible(create);
        // This browser widget runner does not bundle Material's InkSparkle
        // shader. Exercise real callbacks here; pointer/menu behavior is
        // covered by the regular workspace widget tests.
        tester.widget<FilledButton>(create).onPressed!();
        await tester.pumpAndSettle();
        expect(find.byType(ProjectFormPage), findsOneWidget);
        final oldNavigator = Navigator.of(
          tester.element(find.byType(ProjectFormPage)),
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'Emulator private draft',
        );
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.logout))
            .onPressed!();
        await tester.pump();
        await _waitForAuth(tester, services, signedIn: false);
        expect(oldNavigator.mounted, isFalse);
        expect(find.byType(AuthPage), findsOneWidget);
        expect(find.byType(ProjectFormPage), findsNothing);
        expect(find.byType(ProjectHomePage), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        final loginNavigator = tester.state<NavigatorState>(
          find.byType(Navigator),
        );
        expect(loginNavigator.canPop(), isFalse);
        await loginNavigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          // Never flush the emulator globally: interactive users may be testing too.
          try {
            await auth.signIn(email, password);
            await services.auth.currentUser!.delete();
          } on FirebaseException catch (error) {
            if (![
              'user-not-found',
              'invalid-credential',
            ].contains(error.code)) {
              rethrow;
            }
          } finally {
            await services.auth.signOut();
          }
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _waitForAuth(
  WidgetTester tester,
  FirebaseServices services, {
  required bool signedIn,
}) async {
  await tester.runAsync(
    () => services.auth
        .userChanges()
        .firstWhere((user) => (user != null) == signedIn)
        .timeout(const Duration(seconds: 10)),
  );
  await tester.pumpAndSettle();
}
