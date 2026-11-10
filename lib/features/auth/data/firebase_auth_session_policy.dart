import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/foundation/app_failure.dart';
import '../api/auth_repository.dart';
import '../api/auth_session_policy.dart';

/// Uses Firebase's credential storage and retains only a native opt-out flag.
///
/// Bootstrap must await [restore] before exposing any restored account. The
/// caller owns the injected Firebase client and preferences.
final class FirebaseAuthSessionPolicy implements AuthSessionPolicy {
  /// Scopes the preference to this Firebase application and backend.
  FirebaseAuthSessionPolicy({
    required this.auth,
    required this.preferences,
    required this.isWeb,
  });

  final FirebaseAuth auth;
  final SharedPreferences preferences;
  final bool isWeb;

  String get _key =>
      'auth_stay_signed_in_v1/${auth.app.options.projectId}/${auth.app.name}';

  /// Discards a native session opted out of restoration on the previous run.
  ///
  /// Existing installations retain Firebase's persistent default. Invalid
  /// preference values fail closed. Web restoration is owned by Firebase.
  Future<void> restore() async {
    if (isWeb) return;
    final saved = preferences.get(_key);
    if (saved != null && saved != true) {
      await auth.signOut();
    }
  }

  @override
  Future<void> configure({required bool staySignedIn}) async {
    if (isWeb) {
      await auth.setPersistence(
        staySignedIn ? Persistence.LOCAL : Persistence.SESSION,
      );
    } else {
      try {
        if (!await preferences.setBool(_key, staySignedIn)) {
          throw const AuthFailure(
            AuthFailureCode.unavailable,
            FailureKind.unavailable,
          );
        }
      } on PlatformException {
        throw const AuthFailure(
          AuthFailureCode.unavailable,
          FailureKind.unavailable,
        );
      }
    }
  }
}
