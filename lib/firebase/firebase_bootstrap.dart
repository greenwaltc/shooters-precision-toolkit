import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show appFlavor;

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

class FirebaseServices {
  FirebaseServices({required this.app, required this.auth, required this.db});
  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
}

Future<FirebaseServices> bootstrapFirebase() async {
  const environment = String.fromEnvironment('APP_ENV');
  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  final (options, expectedProject) = switch (environment) {
    'dev' => (
      dev.DefaultFirebaseOptions.currentPlatform,
      'bramwellsprecisiontestkitdev',
    ),
    'prod' => (
      prod.DefaultFirebaseOptions.currentPlatform,
      'bramwells-precision-test-kit',
    ),
    _ => throw StateError('Build with APP_ENV=dev or APP_ENV=prod.'),
  };
  if (appFlavor != null && appFlavor != environment) {
    throw StateError('Native flavor and APP_ENV disagree.');
  }
  if (useEmulators && environment == 'prod') {
    throw StateError('A production build cannot select emulators.');
  }
  if (options.projectId != expectedProject) {
    throw StateError('Generated Firebase options select the wrong project.');
  }

  final app = await Firebase.initializeApp(options: options);
  if (app.options.projectId != expectedProject) {
    throw StateError('Initialized Firebase app selects the wrong project.');
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  // Spark examples use the same Standard default database ID everywhere.
  final db = FirebaseFirestore.instanceFor(app: app);
  if (useEmulators) {
    await auth.useAuthEmulator(emulatorHost, 9099);
    db.useFirestoreEmulator(emulatorHost, 8080);
    db.settings = const Settings(persistenceEnabled: false);
  }
  return FirebaseServices(app: app, auth: auth, db: db);
}
