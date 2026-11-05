import 'dart:ui' show PlatformDispatcher;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import 'app/application.dart';
import 'app/config/app_config.dart';
import 'app/firebase/firebase_bootstrap.dart';
import 'app/firebase/firebase_startup.dart';
import 'app/observability/error_boundary.dart';
import 'app/observability/safe_diagnostics.dart';
import 'shared/platform/diagnostic_output_native.dart'
    if (dart.library.js_interop) 'shared/platform/diagnostic_output_web.dart';

export 'app/application.dart' show FirebaseApplication, MyApp;

/// Boots Flutter, validates deployment identity and installs safe reporting.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig? config;
  Object? configurationError;
  StackTrace? configurationStack;
  try {
    config = loadBuildConfig();
  } catch (error, stack) {
    configurationError = error;
    configurationStack = stack;
  }
  final diagnostics = SafeDiagnostics(
    configuration: config,
    write: writeStructuredDiagnostic,
  );
  // Process-owned hooks remain installed until the application shuts down.
  installErrorBoundary(diagnostics, dispatcher: PlatformDispatcher.instance);
  runApp(
    FirebaseStartup(
      diagnostics: diagnostics,
      initialize: () {
        final settings = config;
        if (settings == null) {
          Error.throwWithStackTrace(configurationError!, configurationStack!);
        }
        return bootstrapFirebase(config: settings);
      },
      applicationBuilder: (services) => FirebaseApplication(
        services: services,
        clock: const Clock(),
        diagnostics: diagnostics,
      ),
    ),
  );
}
