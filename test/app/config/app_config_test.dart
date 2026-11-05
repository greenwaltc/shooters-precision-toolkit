import 'dart:convert';
import 'dart:io';

import 'package:bramwells_precision_test_kit/app/config/app_config.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/shared/ui/product_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = {'CONFIG_SCHEMA_VERSION': '1', 'APP_ENV': 'dev'};
  for (final profile in ['dev', 'prod', 'local', 'local-android']) {
    test('$profile reviewed manifest boots with the expected identity', () {
      final values =
          (jsonDecode(File('config/$profile.json').readAsStringSync())
                  as Map<String, Object?>)
              .map((key, value) => MapEntry(key, value! as String));
      final config = AppConfig.fromValues(values);
      expect(config.environment.name, profile == 'prod' ? 'prod' : 'dev');
      expect(config.useEmulators, profile.startsWith('local'));
      expect(
        config.projectId,
        profile.startsWith('local')
            ? AppConfig.localProjectId
            : profile == 'prod'
            ? 'bramwells-precision-test-kit'
            : 'bramwellsprecisiontestkitdev',
      );
      expect(
        config.publicOrigin.scheme,
        profile.startsWith('local') ? 'http' : 'https',
      );
      config.validateNativeFlavor(config.environment.name, required: true);
      expect(
        () => config.validateNativeFlavor('wrong', required: true),
        throwsStateError,
      );
      expect(
        () => config.validateNativeFlavor(null, required: true),
        throwsStateError,
      );
    });
  }
  test('rejects unknown, missing, malformed and unsafe build inputs', () {
    for (final values in <Map<String, String>>[
      {},
      {'APP_ENV': 'dev'},
      {...base, 'CONFIG_SCHEMA_VERSION': '2'},
      {...base, 'APP_ENV': 'staging'},
      {...base, 'UNUSED': 'true'},
      {...base, 'USE_FIREBASE_EMULATORS': 'yes'},
      {...base, 'THEME_MODE_TOGGLE': '1'},
      {...base, 'IMPUTE_MISSING_DATA': 'yes'},
      {...base, 'AUTH_EMULATOR_PORT': '1'},
      {...base, 'FIRESTORE_EMULATOR_PORT': '65536'},
      {...base, 'SAVE_DEBOUNCE_MILLISECONDS': 'NaN'},
      {...base, 'EMAIL_COOLDOWN_SECONDS': '0'},
      {...base, 'FIREBASE_EMULATOR_HOST': 'https://example.test'},
      {...base, 'APP_ENV': 'prod', 'USE_FIREBASE_EMULATORS': 'true'},
    ]) {
      expect(() => AppConfig.fromValues(values), throwsArgumentError);
    }
  });
  for (final enabled in [false, true]) {
    test('feature policy explicitly supports enabled=$enabled', () {
      final config = AppConfig.fromValues({
        ...base,
        'IMPUTE_MISSING_DATA': '$enabled',
        'THEME_MODE_TOGGLE': '$enabled',
      });
      expect(
        config.product.featureFlags.isEnabled(FeatureFlag.themeModeToggle),
        enabled,
      );
      final form = ProjectFormModel(featureFlags: config.product.featureFlags);
      addTearDown(form.dispose);
      form.setImputeMissingData(true);
      expect(form.shouldImputeMissingData, enabled);
    });
  }
}
