import 'package:flutter/material.dart';

import '../../shared/foundation/diagnostics.dart';
import '../../shared/l10n/app_copy.dart';
import 'firebase_bootstrap.dart';

/// Shows startup failures without exposing SDK errors or configuration to users.
class FirebaseStartup extends StatefulWidget {
  const FirebaseStartup({
    super.key,
    required this.initialize,
    required this.applicationBuilder,
    this.diagnostics = const NoopDiagnostics(),
  });

  final Diagnostics diagnostics;
  final Future<FirebaseServices> Function() initialize;
  final Widget Function(FirebaseServices) applicationBuilder;

  @override
  State<FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<FirebaseStartup> {
  late final Future<FirebaseServices> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<FirebaseServices> _initialize() async {
    final elapsed = Stopwatch()..start();
    try {
      final services = await widget.initialize();
      widget.diagnostics.record(
        DiagnosticEvent.startupReady,
        elapsed: elapsed.elapsed,
      );
      return services;
    } catch (error, stack) {
      widget.diagnostics.record(
        DiagnosticEvent.startupFailed,
        error: error,
        stack: stack,
        elapsed: elapsed.elapsed,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseServices>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return widget.applicationBuilder(snapshot.requireData);
      }
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      AppCopy.english.unableToStartTheAppCheckYourConnection,
                      textAlign: TextAlign.center,
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
