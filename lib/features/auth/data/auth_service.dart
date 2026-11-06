import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/foundation/diagnostics.dart';
import '../api/auth_repository.dart';

/// A Firebase implementation of the app's account operations.
///
/// Translates Firebase failures into [AuthFailure] so callers can handle them
/// without displaying provider details.
class AuthService implements AuthRepository {
  /// Creates an adapter around an existing [auth] client.
  ///
  /// [returnOrigin] is the destination used by verification and password reset
  /// links.
  AuthService(
    this.auth, {
    required this.returnOrigin,
    required this.emailCooldown,
    required this.clock,
    this.diagnostics = const NoopDiagnostics(),
  });
  final Uri returnOrigin;
  @override
  final Duration emailCooldown;
  @override
  final Clock clock;
  final FirebaseAuth auth;
  final Diagnostics diagnostics;
  Future<void>? _pendingRegistration;
  final _verificationRetryTimes = <String, DateTime>{};

  @override
  Future<void>? get pendingRegistration => _pendingRegistration;

  @override
  DateTime? get verificationEmailRetryAt =>
      _verificationRetryTimes[auth.currentUser?.uid];

  @override
  String get sessionNamespace => auth.app.options.projectId;
  AuthAccount? _account(User? user) => user == null
      ? null
      : AuthAccount(
          uid: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
        );
  @override
  AuthAccount? get currentUser => _account(auth.currentUser);
  @override
  Stream<AuthAccount?> userChanges() => auth
      .userChanges()
      .map(_account)
      .transform(
        StreamTransformer<AuthAccount?, AuthAccount?>.fromHandlers(
          handleError:
              (Object error, StackTrace stack, EventSink<AuthAccount?> sink) =>
                  sink.addError(
                    error is FirebaseAuthException
                        ? mapAuthFailure(error.code)
                        : error,
                    stack,
                  ),
        ),
      );
  @override
  Future<bool> verifiedToken(AuthAccount account) => _guard(() async {
    final user = auth.currentUser;
    if (user == null || user.uid != account.uid || !account.emailVerified) {
      return false;
    }
    final token = await user.getIdTokenResult(true);
    return auth.currentUser?.uid == account.uid &&
        token.claims?['email_verified'] == true;
  });
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error, stack) {
      final failure = mapAuthFailure(error.code);
      diagnostics.record(
        DiagnosticEvent.authFailed,
        error: failure,
        stack: stack,
      );
      Error.throwWithStackTrace(failure, stack);
    }
  }

  @override
  Future<void> register(String email, String password) async {
    final request = _guard(() => _register(email, password));
    _pendingRegistration = request;
    try {
      await request;
    } finally {
      if (identical(_pendingRegistration, request)) {
        _pendingRegistration = null;
      }
    }
  }

  @override
  Future<void> signIn(String email, String password) =>
      _guard(() => _signIn(email, password));
  @override
  Future<void> sendVerification() => _guard(_sendVerification);
  @override
  Future<bool> refreshVerification() => _guard(_refreshVerification);
  @override
  Future<void> resetPassword(String email) =>
      _guard(() => _resetPassword(email));
  @override
  Future<void> signOut() => _guard(_signOut);

  Future<void> _register(String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.sendEmailVerification(_emailActionSettings);
    _startVerificationCooldown(user.uid);
  }

  Future<void> _signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> _sendVerification() async {
    final user = auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before requesting verification.');
    }

    if (_pendingRegistration != null ||
        (_verificationRetryTimes[user.uid]?.isAfter(clock.now()) ?? false)) {
      throw const AuthFailure(
        AuthFailureCode.rateLimited,
        FailureKind.unavailable,
      );
    }

    _startVerificationCooldown(user.uid);
    await user.sendEmailVerification(_emailActionSettings);
  }

  void _startVerificationCooldown(String uid) {
    final now = clock.now();
    _verificationRetryTimes.removeWhere((_, retryAt) => !retryAt.isAfter(now));
    _verificationRetryTimes[uid] = now.add(emailCooldown);
  }

  Future<bool> _refreshVerification() async {
    await auth.currentUser?.reload();

    final user = auth.currentUser;
    if (user == null || !user.emailVerified) {
      return false;
    }

    await user.getIdToken(true);
    return true;
  }

  Future<void> _resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: _emailActionSettings,
      );
    } on FirebaseAuthException catch (error) {
      // Keep the response the same for unknown addresses.
      if (error.code != 'user-not-found') {
        rethrow;
      }
    }
  }

  Future<void> _signOut() => auth.signOut();

  ActionCodeSettings get _emailActionSettings {
    final returnUrl = returnOrigin.toString();

    return ActionCodeSettings(url: returnUrl, handleCodeInApp: false);
  }
}

/// Maps a Firebase error [code] to a safe application error.
///
/// Unrecognized codes map to an unknown failure.
AuthFailure mapAuthFailure(String code) => switch (code) {
  'invalid-email' => const AuthFailure(
    AuthFailureCode.invalidEmail,
    FailureKind.invalidInput,
  ),
  'weak-password' || 'password-does-not-meet-requirements' => const AuthFailure(
    AuthFailureCode.passwordPolicy,
    FailureKind.invalidInput,
  ),
  'email-already-in-use' => const AuthFailure(
    AuthFailureCode.accountExists,
    FailureKind.conflict,
  ),
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => const AuthFailure(
    AuthFailureCode.invalidCredentials,
    FailureKind.unauthenticated,
  ),
  'too-many-requests' => const AuthFailure(
    AuthFailureCode.rateLimited,
    FailureKind.unavailable,
  ),
  'network-request-failed' => const AuthFailure(
    AuthFailureCode.unavailable,
    FailureKind.unavailable,
  ),
  'user-token-expired' ||
  'invalid-user-token' ||
  'user-disabled' => const AuthFailure(
    AuthFailureCode.expiredSession,
    FailureKind.unauthenticated,
  ),
  _ => const AuthFailure(AuthFailureCode.unknown, FailureKind.unknown),
};
