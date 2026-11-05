/// Named application events with fixed categories for structured reporting.
enum DiagnosticEvent {
  startupReady('bootstrap', 'info', 'success'),
  startupFailed('bootstrap', 'error', 'failure'),
  frameworkError('flutter', 'error', 'failure'),
  uncaughtAsyncError('runtime', 'error', 'failure'),
  authFailed('auth', 'warning', 'failure'),
  contactSendFailed('contact', 'warning', 'failure'),
  workspaceLoadFailed('workspace', 'warning', 'failure'),
  workspaceSaveFailed('workspace', 'warning', 'failure'),
  exportFailed('export', 'warning', 'failure');

  /// Associates an event with its component, severity, and outcome.
  const DiagnosticEvent(this.component, this.severity, this.outcome);
  final String component;
  final String severity;
  final String outcome;
}

/// The caller supplies operation context only. The reporting boundary owns
/// classification and redaction; raw details must never reach its output sink.
abstract interface class Diagnostics {
  /// Records an event and any available failure, stack, or duration.
  ///
  /// The reporting boundary decides which details are safe to emit. Callers
  /// must avoid attaching private payloads.
  void record(
    DiagnosticEvent event, {
    Object? error,
    StackTrace? stack,
    Duration? elapsed,
  });
}

/// A diagnostics sink that discards all events.
final class NoopDiagnostics implements Diagnostics {
  /// Creates a diagnostics sink for callers that need no reporting.
  const NoopDiagnostics();
  @override
  void record(
    DiagnosticEvent event, {
    Object? error,
    StackTrace? stack,
    Duration? elapsed,
  }) {}
}
