import 'package:clock/clock.dart';

import '../../../shared/foundation/app_failure.dart';

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

final class AuthFailure extends AppFailure {
  const AuthFailure(this.code, super.kind);
  final AuthFailureCode code;
}

final class AuthAccount {
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
  Clock get clock;
  Duration get emailCooldown;
  String get sessionNamespace;
  AuthAccount? get currentUser;
  Stream<AuthAccount?> userChanges();
  Future<bool> verifiedToken(AuthAccount account);
  Future<void> register(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> sendVerification();
  Future<bool> refreshVerification();
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
