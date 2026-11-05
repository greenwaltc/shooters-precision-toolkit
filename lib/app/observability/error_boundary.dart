import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../../shared/foundation/diagnostics.dart';
import '../../shared/l10n/app_copy.dart';

/// Installs framework and uncaught-async handlers. Test/host owners can restore
/// their hooks; ordinary app startup owns these for the process lifetime.
VoidCallback installErrorBoundary(
  Diagnostics diagnostics, {
  required PlatformDispatcher dispatcher,
}) {
  final priorFlutter = FlutterError.onError;
  final priorPlatform = dispatcher.onError;
  final priorWidget = ErrorWidget.builder;
  FlutterError.onError = (details) => diagnostics.record(
    DiagnosticEvent.frameworkError,
    error: details.exception,
    stack: details.stack,
  );
  dispatcher.onError = (error, stack) {
    diagnostics.record(
      DiagnosticEvent.uncaughtAsyncError,
      error: error,
      stack: stack,
    );
    return true;
  };
  ErrorWidget.builder = (_) => const _SafeFailureSurface();
  return () {
    FlutterError.onError = priorFlutter;
    dispatcher.onError = priorPlatform;
    ErrorWidget.builder = priorWidget;
  };
}

class _SafeFailureSurface extends StatelessWidget {
  const _SafeFailureSurface();
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppCopy.english.unexpectedAppError,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
