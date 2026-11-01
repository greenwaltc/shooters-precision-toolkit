import 'dart:async';

import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// A controllable Auth boundary for error cases that emulators cannot inject.
class FakeAuth extends Fake implements FirebaseAuth {
  FakeAuth({FakeAuthUser? initialUser}) {
    if (initialUser != null) users[initialUser.email!] = initialUser;
    switchUser(initialUser);
  }

  final users = <String, FakeAuthUser>{};
  final _changes = StreamController<User?>.broadcast(sync: true);
  FakeAuthUser? _user;
  int registrations = 0;
  int newUserVerificationFailures = 0;
  final passwordResetRequests = <String>[];

  @override
  final FirebaseApp app = _App();

  FirebaseServices get services =>
      FirebaseServices(app: app, auth: this, db: _Firestore());

  @override
  FakeAuthUser? get currentUser => _user;

  @override
  Stream<User?> userChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  void switchUser(FakeAuthUser? user) {
    _user = user;
    if (user != null) {
      user.onReload = () => _changes.add(_user);
    }
    _changes.add(user);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registrations++;
    final user = FakeAuthUser(uid: 'created-$registrations', email: email)
      ..verificationFailures = newUserVerificationFailures;
    users[email] = user;
    switchUser(user);
    return _Credential(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = users[email];
    if (user == null) throw FirebaseAuthException(code: 'invalid-credential');
    switchUser(user);
    return _Credential(user);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    passwordResetRequests.add(email);
    if (!users.containsKey(email)) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
  }

  @override
  Future<void> signOut() async => switchUser(null);

  Future<void> dispose() => _changes.close();
}

class FakeAuthUser extends Fake implements User {
  FakeAuthUser({required this.uid, required this.email, bool verified = false})
    : _verified = verified,
      serverVerified = verified;

  @override
  final String uid;
  @override
  final String? email;
  bool _verified;
  bool serverVerified;
  int verificationFailures = 0;
  int verificationRequests = 0;
  int forcedTokenRefreshes = 0;
  Completer<IdTokenResult>? tokenRefresh;
  void Function()? onReload;

  @override
  bool get emailVerified => _verified;

  @override
  Future<void> reload() async {
    _verified = serverVerified;
    onReload?.call();
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (forceRefresh) forcedTokenRefreshes++;
    return 'fake-token';
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    if (forceRefresh) forcedTokenRefreshes++;
    if (tokenRefresh != null) return tokenRefresh!.future;
    return FakeTokenResult(serverVerified);
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    verificationRequests++;
    if (verificationFailures > 0) {
      verificationFailures--;
      throw FirebaseAuthException(code: 'network-request-failed');
    }
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
}

class FakeTokenResult extends Fake implements IdTokenResult {
  FakeTokenResult(this.verified);
  final bool verified;
  @override
  Map<String, dynamic> get claims => {'email_verified': verified};
}

class _App extends Fake implements FirebaseApp {
  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'test-only',
    appId: 'test-only',
    messagingSenderId: 'test-only',
    projectId: 'bramwellsprecisiontestkitdev',
  );
}

class _Firestore extends Fake implements FirebaseFirestore {}
