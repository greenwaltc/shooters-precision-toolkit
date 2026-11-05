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
  const AppFailure(this.kind);
  final FailureKind kind;
  @override
  String toString() => 'AppFailure(${kind.name})';
}
