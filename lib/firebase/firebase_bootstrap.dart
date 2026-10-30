import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show appFlavor;

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

class FirebaseServices {
  FirebaseServices({required this.app, required this.auth, required this.db});
  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
}

const localFirebaseProjectId = 'demo-bramwellsprecisiontestkit';

/// Resolve the project before initializing any SDK or accessing a service.
String firebaseProjectFor({
  required String environment,
  required bool useEmulators,
  String? nativeFlavor,
}) {
  final cloudProject = switch (environment) {
    'dev' => 'bramwellsprecisiontestkitdev',
    'prod' => 'bramwells-precision-test-kit',
    _ => throw StateError('Build with APP_ENV=dev or APP_ENV=prod.'),
  };
  if (nativeFlavor != null && nativeFlavor != environment) {
    throw StateError('Native flavor and APP_ENV disagree.');
  }
  if (useEmulators && environment == 'prod') {
    throw StateError('A production build cannot select emulators.');
  }
  return useEmulators ? localFirebaseProjectId : cloudProject;
}

Future<FirebaseServices> bootstrapFirebase() async {
  const environment = String.fromEnvironment('APP_ENV');
  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  final expectedProject = firebaseProjectFor(
    environment: environment,
    useEmulators: useEmulators,
    nativeFlavor: appFlavor,
  );

  late final FirebaseApp app;
  if (useEmulators) {
    // No real project configuration or credentials are used for local services.
    app = await Firebase.initializeApp(demoProjectId: localFirebaseProjectId);
  } else {
    final options = environment == 'dev'
        ? dev.DefaultFirebaseOptions.currentPlatform
        : prod.DefaultFirebaseOptions.currentPlatform;
    if (options.projectId != expectedProject) {
      throw StateError('Generated Firebase options select the wrong project.');
    }
    app = await Firebase.initializeApp(options: options);
  }
  if (app.options.projectId != expectedProject) {
    throw StateError('Initialized Firebase app selects the wrong project.');
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  // Spark examples use the same Standard default database ID everywhere.
  final db = FirebaseFirestore.instanceFor(app: app);
  if (useEmulators) {
    await auth.useAuthEmulator(emulatorHost, 9099);
    if (kIsWeb) await auth.setPersistence(Persistence.NONE);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator(emulatorHost, 8080);
  }
  return FirebaseServices(app: app, auth: auth, db: db);
}
