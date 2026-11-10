import 'package:clock/clock.dart';

import '../../../shared/foundation/app_failure.dart';

/// Account operation failures that the app can present to users.
enum AuthFailureCode {
  invalidEmail,
  passwordPolicy,
  accountExists,
  invalidCredentials,
  rateLimited,
  unavailable,
  expiredSession,
  unknown,
}

/// A safe account error with an app-defined reason and a general failure
/// category.
final class AuthFailure extends AppFailure {
  /// Associates an account-specific [code] with a general failure category.
  const AuthFailure(this.code, super.kind);
  final AuthFailureCode code;
}

/// The account identity and email verification state used by the app.
final class AuthAccount {
  /// Creates an account snapshot. An account may have no email address.
  const AuthAccount({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });
  final String uid;
  final String? email;
  final bool emailVerified;
}

/// Owns one authentication client and its email-action policy. SDK accounts and
/// tokens remain inside the adapter. The UI never receives session credentials.
abstract interface class AuthRepository {
  /// The clock used to determine when account actions can be retried.
  Clock get clock;

  /// The wait between email requests.
  Duration get emailCooldown;

  /// The signup request, including its initial verification email, while it
  /// is pending. It completes with the same result as [register].
  Future<void>? get pendingRegistration;

  /// The earliest retry time for the current account's verification email,
  /// or null when it has no recorded cooldown in this app session.
  DateTime? get verificationEmailRetryAt;

  /// The scope used to distinguish accounts that belong to different backends.
  String get sessionNamespace;

  /// The currently signed-in account, or null when signed out.
  AuthAccount? get currentUser;

  /// Watches the initial account and subsequent account changes.
  ///
  /// Emits null when the user is signed out. Account service failures can
  /// arrive as stream errors.
  Stream<AuthAccount?> userChanges();

  /// Checks a fresh token for the verified email claim.
  ///
  /// Returns false when [account] is unverified or no longer the active
  /// account. A token refresh failure completes the future with an error.
  Future<bool> verifiedToken(AuthAccount account);

  /// Creates an account with [email] and [password] and requests a verification
  /// email.
  ///
  /// If sending the email fails after registration, the account can still exist
  /// and be signed in.
  /// [staySignedIn] follows the same session policy as [signIn].
  Future<void> register(
    String email,
    String password, {
    bool staySignedIn = true,
  });

  /// Signs in using [email] and [password].
  ///
  /// Rejected credentials complete the future with an [AuthFailure].
  /// With [staySignedIn] (the default), Firebase may restore the session after
  /// restart. Otherwise it lasts for the browser tab or native process only.
  Future<void> signIn(
    String email,
    String password, {
    bool staySignedIn = true,
  });

  /// Requests a verification email for the current account.
  ///
  /// Requires a signed-in account. The Firebase implementation reports missing
  /// sign-in as a [StateError] and an active cooldown as an [AuthFailure].
  Future<void> sendVerification();

  /// Reloads the current account and refreshes its token when verified.
  ///
  /// Returns false when there is no current account or its email is still
  /// unverified.
  Future<bool> refreshVerification();

  /// Requests a password reset email.
  ///
  /// Successful completion does not confirm that [email] belongs to an existing
  /// account.
  Future<void> resetPassword(String email);

  /// Ends the current sign-in session.
  Future<void> signOut();
}
