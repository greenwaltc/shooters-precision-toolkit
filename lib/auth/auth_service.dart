import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firebase_bootstrap.dart';

class AuthService {
  AuthService(this.auth);
  final FirebaseAuth auth;

  Future<void> register(String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.sendEmailVerification(_emailActionSettings);
  }

  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendVerification() async {
    final user = auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before requesting verification.');
    }

    await user.sendEmailVerification(_emailActionSettings);
  }

  Future<bool> refreshVerification() async {
    await auth.currentUser?.reload();

    final user = auth.currentUser;
    if (user == null || !user.emailVerified) return false;

    await user.getIdToken(true);
    return true;
  }

  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: _emailActionSettings,
      );
    } on FirebaseAuthException catch (error) {
      // Keep the response the same for unknown addresses.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  Future<void> signOut() => auth.signOut();

  ActionCodeSettings get _emailActionSettings {
    final returnUrl = switch (auth.app.options.projectId) {
      localFirebaseProjectId => 'http://127.0.0.1:7357',
      'bramwellsprecisiontestkitdev' => 'https://dev.bramwelltest.com',
      'bramwells-precision-test-kit' => 'https://bramwelltest.com',
      _ => throw StateError('Unknown Firebase project.'),
    };

    return ActionCodeSettings(url: returnUrl, handleCodeInApp: false);
  }
}
