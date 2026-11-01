import 'package:flutter/material.dart';

import 'firebase_bootstrap.dart';

/// Shows startup failures without exposing SDK errors or configuration to users.
class FirebaseStartup extends StatefulWidget {
  const FirebaseStartup({
    super.key,
    required this.initialize,
    required this.applicationBuilder,
  });

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
    _initialization = Future.sync(widget.initialize);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseServices>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return widget.applicationBuilder(snapshot.requireData);
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Unable to start the app. Check your connection and '
                      'restart the app. If this continues, contact support.',
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
