import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show appFlavor;

import 'auth_emulator_hint_stub.dart'
    if (dart.library.js_interop) 'auth_emulator_hint_web.dart';
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
  bool requireNativeFlavor = false,
}) {
  final cloudProject = switch (environment) {
    'dev' => 'bramwellsprecisiontestkitdev',
    'prod' => 'bramwells-precision-test-kit',
    _ => throw StateError('Build with APP_ENV=dev or APP_ENV=prod.'),
  };
  if ((requireNativeFlavor && nativeFlavor == null) ||
      (nativeFlavor != null && nativeFlavor != environment)) {
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
    requireNativeFlavor:
        !kIsWeb &&
        const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform),
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
  // Cloud-only application: do not retain Firestore documents across sessions.
  db.settings = const Settings(persistenceEnabled: false);
  if (useEmulators) {
    await connectAuthToEmulator(auth, emulatorHost, 9099);
    db.useFirestoreEmulator(emulatorHost, 8080);
  }
  return FirebaseServices(app: app, auth: auth, db: db);
}

/// Reapply the emulator connection even if a web hot restart left a stale hint.
Future<void> connectAuthToEmulator(
  FirebaseAuth auth,
  String host,
  int port,
) async {
  clearAuthEmulatorHint(auth.app.name);
  await auth.useAuthEmulator(host, port);
  if (kIsWeb) {
    await auth.setPersistence(Persistence.NONE);
  }
}
