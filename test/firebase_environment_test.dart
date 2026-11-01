import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local services use a demo project independent of dev credentials', () {
    expect(
      firebaseProjectFor(environment: 'dev', useEmulators: true),
      localFirebaseProjectId,
    );
  });

  test('cloud builds retain their separate project IDs', () {
    expect(
      firebaseProjectFor(environment: 'dev', useEmulators: false),
      'bramwellsprecisiontestkitdev',
    );
    expect(
      firebaseProjectFor(environment: 'prod', useEmulators: false),
      'bramwells-precision-test-kit',
    );
  });

  test('production cannot use emulators', () {
    expect(
      () => firebaseProjectFor(environment: 'prod', useEmulators: true),
      throwsStateError,
    );
  });

  test('missing environments and mismatched native flavors fail closed', () {
    expect(
      () => firebaseProjectFor(environment: '', useEmulators: true),
      throwsStateError,
    );
    expect(
      () => firebaseProjectFor(
        environment: 'dev',
        useEmulators: true,
        nativeFlavor: 'prod',
      ),
      throwsStateError,
    );
  });
}
