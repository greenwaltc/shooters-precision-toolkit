import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> resetPassword(String email) => auth.sendPasswordResetEmail(
    email: email.trim(),
    actionCodeSettings: _emailActionSettings,
  );

  Future<void> refreshVerification() async {
    await auth.currentUser?.reload();
    await auth.currentUser?.getIdToken(true);
  }

  Future<void> signOut() => auth.signOut();

  ActionCodeSettings get _emailActionSettings {
    final returnUrl = switch (auth.app.options.projectId) {
      'bramwellsprecisiontestkitdev' =>
        'https://bramwellsprecisiontestkitdev.web.app',
      'bramwells-precision-test-kit' =>
        'https://bramwells-precision-test-kit.web.app',
      _ => throw StateError('Unknown Firebase project.'),
    };

    return ActionCodeSettings(url: returnUrl, handleCodeInApp: false);
  }
}
