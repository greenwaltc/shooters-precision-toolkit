import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show appFlavor;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/api/auth_session_policy.dart';
import '../../features/auth/data/firebase_auth_session_policy.dart';
import '../config/app_config.dart';
import 'auth_emulator_hint_stub.dart'
    if (dart.library.js_interop) 'auth_emulator_hint_web.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

/// The initialized Firebase app, account service, and project database for one
/// configuration.
class FirebaseServices {
  /// Groups clients that have already been configured for the same Firebase
  /// app.
  FirebaseServices({
    required this.app,
    required this.auth,
    required this.db,
    required this.config,
    required this.sessions,
  });
  final AppConfig config;
  final FirebaseApp app;
  final FirebaseAuth auth;
  final AuthSessionPolicy sessions;
  final FirebaseFirestore db;
}

const localFirebaseProjectId = AppConfig.localProjectId;

/// Resolve the project before initializing any SDK or accessing a service.
String firebaseProjectFor({
  required String environment,
  required bool useEmulators,
  String? nativeFlavor,
  bool requireNativeFlavor = false,
}) {
  try {
    final config = AppConfig.fromValues({
      'CONFIG_SCHEMA_VERSION': AppConfig.schemaVersion,
      'APP_ENV': environment,
      'USE_FIREBASE_EMULATORS': '$useEmulators',
    });
    config.validateNativeFlavor(nativeFlavor, required: requireNativeFlavor);
    return config.projectId;
  } on ArgumentError {
    throw StateError('Invalid Firebase deployment configuration.');
  }
}

/// Initializes Firebase and configures authentication and project storage.
///
/// If [config] is omitted, reads the build configuration. Throws [StateError]
/// if the native flavor or initialized Firebase project disagrees with that
/// configuration. When emulators are enabled, connects both services before
/// returning.
Future<FirebaseServices> bootstrapFirebase({AppConfig? config}) async {
  final settings = config ?? loadBuildConfig();
  final environment = settings.environment.name;
  final useEmulators = settings.useEmulators;
  final emulatorHost = settings.emulatorHost;
  settings.validateNativeFlavor(
    appFlavor,
    required:
        !kIsWeb &&
        const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform),
  );
  final expectedProject = settings.projectId;

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
    await connectAuthToEmulator(auth, emulatorHost, settings.authEmulatorPort);
    db.useFirestoreEmulator(emulatorHost, settings.firestoreEmulatorPort);
  }
  final sessions = FirebaseAuthSessionPolicy(
    auth: auth,
    preferencesLoader: SharedPreferences.getInstance,
    isWeb: kIsWeb,
  );
  await sessions.restore();
  return FirebaseServices(
    app: app,
    auth: auth,
    db: db,
    config: settings,
    sessions: sessions,
  );
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
