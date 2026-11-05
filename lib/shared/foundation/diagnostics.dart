enum DiagnosticEvent {
  startupReady('bootstrap', 'info', 'success'),
  startupFailed('bootstrap', 'error', 'failure'),
  frameworkError('flutter', 'error', 'failure'),
  uncaughtAsyncError('runtime', 'error', 'failure'),
  authFailed('auth', 'warning', 'failure'),
  workspaceLoadFailed('workspace', 'warning', 'failure'),
  workspaceSaveFailed('workspace', 'warning', 'failure'),
  exportFailed('export', 'warning', 'failure');

  const DiagnosticEvent(this.component, this.severity, this.outcome);
  final String component;
  final String severity;
  final String outcome;
}

/// The caller supplies operation context only. The reporting boundary owns
/// classification and redaction; raw details must never reach its output sink.
abstract interface class Diagnostics {
  void record(
    DiagnosticEvent event, {
    Object? error,
    StackTrace? stack,
    Duration? elapsed,
  });
}

final class NoopDiagnostics implements Diagnostics {
  const NoopDiagnostics();
  @override
  void record(
    DiagnosticEvent event, {
    Object? error,
    StackTrace? stack,
    Duration? elapsed,
  }) {}
}
