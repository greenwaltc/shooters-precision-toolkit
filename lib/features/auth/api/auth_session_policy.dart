/// Controls whether the authentication SDK may restore a session after restart.
///
/// Implementations own persistence policy, never passwords or copies of tokens.
abstract interface class AuthSessionPolicy {
  /// Applies the user's choice before signing in or creating an account.
  ///
  /// A failed policy change must prevent the authentication attempt.
  Future<void> configure({required bool staySignedIn});
}
