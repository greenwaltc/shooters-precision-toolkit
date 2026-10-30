@TestOn('browser')
library;

import 'dart:convert';

import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/widgets/project_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Browser widget tests don't run the application's generated plugin registrant.
  final registrar = Registrar();
  FirebaseCoreWeb.registerWith(registrar);
  FirebaseAuthWeb.registerWith(registrar);
  FirebaseFirestoreWeb.registerWith(registrar);

  testWidgets(
    'Flutter boots with local Auth and Firestore services',
    (tester) async {
      const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
      expect(useEmulators, isTrue, reason: 'Run through task emulators:test.');
      SharedPreferences.setMockInitialValues({});

      final services = await tester.runAsync(() async {
        final services = await bootstrapFirebase().timeout(
          const Duration(seconds: 30),
        );
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
      await tester.pumpAndSettle();
      expect(find.byType(ProjectHomePage), findsOneWidget);
      expect(find.textContaining('Unable to start the app'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
