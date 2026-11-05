import 'package:bramwells_precision_test_kit/app/firebase/firebase_options_dev.dart'
    as dev;
import 'package:bramwells_precision_test_kit/app/firebase/firebase_options_prod.dart'
    as prod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native dev options select the dev project and suffixed Apple bundle',
    () {
      for (final options in [
        dev.DefaultFirebaseOptions.android,
        dev.DefaultFirebaseOptions.ios,
        dev.DefaultFirebaseOptions.macos,
      ]) {
        expect(options.projectId, 'bramwellsprecisiontestkitdev');
      }
      expect(
        dev.DefaultFirebaseOptions.ios.iosBundleId,
        'com.bramwell.bramwellsPrecisionTestKit.dev',
      );
      expect(
        dev.DefaultFirebaseOptions.macos.iosBundleId,
        dev.DefaultFirebaseOptions.ios.iosBundleId,
      );
    },
  );

  test(
    'native prod options preserve production identity and web configuration',
    () {
      for (final options in [
        prod.DefaultFirebaseOptions.web,
        prod.DefaultFirebaseOptions.android,
        prod.DefaultFirebaseOptions.ios,
        prod.DefaultFirebaseOptions.macos,
      ]) {
        expect(options.projectId, 'bramwells-precision-test-kit');
      }
      expect(
        prod.DefaultFirebaseOptions.ios.iosBundleId,
        'com.bramwell.bramwellsPrecisionTestKit',
      );
      expect(
        dev.DefaultFirebaseOptions.web.projectId,
        'bramwellsprecisiontestkitdev',
      );
    },
  );
}
