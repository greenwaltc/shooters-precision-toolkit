import 'dart:async';

import 'package:bramwells_precision_test_kit/features/auth/api/auth_repository.dart';
import 'package:bramwells_precision_test_kit/features/auth/data/auth_service.dart';
import 'package:bramwells_precision_test_kit/features/auth/data/firebase_auth_session_policy.dart';
import 'package:clock/clock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final stay in [false, true]) {
    test('native restoration honors stay signed in = $stay', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final user = FakeAuthUser(uid: 'alice', email: 'alice@example.test');
      final auth = FakeAuth(initialUser: user);
      final policy = FirebaseAuthSessionPolicy(
        auth: auth,
        preferencesLoader: () async => preferences,
        isWeb: false,
      );
      await policy.configure(staySignedIn: stay);
      expect(preferences.getKeys(), hasLength(1));
      expect(preferences.get(preferences.getKeys().single), stay);
      // New policy instance represents the next process, before AuthGate runs.
      await FirebaseAuthSessionPolicy(
        auth: auth,
        preferencesLoader: () async => preferences,
        isWeb: false,
      ).restore();
      expect(auth.currentUser, stay ? same(user) : isNull);
    });

    test(
      'web uses Firebase ${stay ? "local" : "session"} persistence',
      () async {
        final auth = _WebAuth();
        final policy = FirebaseAuthSessionPolicy(
          auth: auth,
          preferencesLoader: () =>
              throw StateError('Web must not load native preferences.'),
          isWeb: true,
        );
        await policy.restore();
        await policy.configure(staySignedIn: stay);
        expect(
          auth.persistence,
          stay ? Persistence.LOCAL : Persistence.SESSION,
        );
      },
    );
  }

  test(
    'legacy native sessions retain Firebase restoration by default',
    () async {
      SharedPreferences.setMockInitialValues({});
      final user = FakeAuthUser(uid: 'alice', email: 'alice@example.test');
      final auth = FakeAuth(initialUser: user);
      await FirebaseAuthSessionPolicy(
        auth: auth,
        preferencesLoader: SharedPreferences.getInstance,
        isWeb: false,
      ).restore();
      expect(auth.currentUser, same(user));
    },
  );

  for (final throwsPlatformError in [false, true]) {
    test(
      'native storage failure is a safe auth failure, throws=$throwsPlatformError',
      () async {
        final policy = FirebaseAuthSessionPolicy(
          auth: FakeAuth(),
          preferencesLoader: () async =>
              _FailingPreferences(throwsPlatformError),
          isWeb: false,
        );
        await expectLater(
          policy.configure(staySignedIn: false),
          throwsA(
            isA<AuthFailure>().having(
              (error) => error.code,
              'code',
              AuthFailureCode.unavailable,
            ),
          ),
        );
      },
    );
  }

  test('invalid native preference clears a restored session', () async {
    SharedPreferences.setMockInitialValues({
      'auth_stay_signed_in_v1/bramwellsprecisiontestkitdev/[DEFAULT]':
          'invalid',
    });
    final auth = FakeAuth(
      initialUser: FakeAuthUser(uid: 'alice', email: 'alice@example.test'),
    );
    await FirebaseAuthSessionPolicy(
      auth: auth,
      preferencesLoader: SharedPreferences.getInstance,
      isWeb: false,
    ).restore();
    expect(auth.currentUser, isNull);
  });

  test(
    'sign-in waits for the requested policy before exposing an account',
    () async {
      final auth = FakeAuth();
      auth.users['alice@example.test'] = FakeAuthUser(
        uid: 'alice',
        email: 'alice@example.test',
      );
      auth.sessions.pending = Completer<void>();
      final service = _service(auth);
      final pending = service.signIn(
        'alice@example.test',
        'test-password',
        staySignedIn: false,
      );
      expect(auth.currentUser, isNull);
      auth.sessions.pending!.complete();
      await pending;
      expect(auth.sessions.staySignedIn, isFalse);
      expect(auth.currentUser?.uid, 'alice');
      await service.signOut();
      expect(auth.currentUser, isNull);
    },
  );

  test('persistence failure prevents sign-in and registration', () async {
    final auth = FakeAuth();
    auth.sessions.failure = FirebaseAuthException(
      code: 'network-request-failed',
    );
    for (final register in [false, true]) {
      final service = _service(auth);
      await expectLater(
        register
            ? service.register('alice@example.test', 'test-password')
            : service.signIn('alice@example.test', 'test-password'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.code,
            'code',
            AuthFailureCode.unavailable,
          ),
        ),
      );
      expect(auth.currentUser, isNull);
      expect(auth.registrations, 0);
    }
  });
}

AuthService _service(FakeAuth auth) => AuthService(
  auth,
  sessions: auth.sessions,
  returnOrigin: Uri.parse('http://127.0.0.1:7357'),
  emailCooldown: const Duration(seconds: 60),
  clock: const Clock(),
);

class _WebAuth extends FakeAuth {
  Persistence? persistence;

  @override
  Future<void> setPersistence(Persistence persistence) async {
    this.persistence = persistence;
  }
}

class _FailingPreferences extends Fake implements SharedPreferences {
  _FailingPreferences(this.throwsPlatformError);
  final bool throwsPlatformError;

  @override
  Future<bool> setBool(String key, bool value) async {
    if (throwsPlatformError) throw PlatformException(code: 'storage-failed');
    return false;
  }
}
