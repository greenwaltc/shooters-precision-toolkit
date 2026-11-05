/// Categories callers can use to handle an operation failure without reading
/// provider details.
enum FailureKind {
  invalidData,
  invalidInput,
  unavailable,
  denied,
  unauthenticated,
  conflict,
  unknown,
}

/// Expected recoverable failure. No vendor messages or private payloads cross
/// this boundary; adapters preserve the original stack when translating.
class AppFailure implements Exception {
  /// Creates an error identified by a safe failure category.
  const AppFailure(this.kind);
  final FailureKind kind;
  @override
  String toString() => 'AppFailure(${kind.name})';
}
