import '../../shared/ui/product_configuration.dart';

enum AppEnvironment { dev, prod }

/// Validated, immutable public inputs for one artifact. No credentials belong here.
final class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.useEmulators,
    required this.emulatorHost,
    required this.authEmulatorPort,
    required this.firestoreEmulatorPort,
    required this.saveDebounce,
    required this.emailCooldown,
    required this.product,
    required this.build,
  });

  static const schemaVersion = '1';
  static const localProjectId = 'demo-bramwellsprecisiontestkit';
  static const keys = {
    'CONFIG_SCHEMA_VERSION',
    'APP_ENV',
    'USE_FIREBASE_EMULATORS',
    'FIREBASE_EMULATOR_HOST',
    'AUTH_EMULATOR_PORT',
    'FIRESTORE_EMULATOR_PORT',
    'SAVE_DEBOUNCE_MILLISECONDS',
    'EMAIL_COOLDOWN_SECONDS',
    'IMPUTE_MISSING_DATA',
    'THEME_MODE_TOGGLE',
    'BUILD_ID',
    'BUILD_VERSION',
    'BUILD_REVISION',
    'BUILD_FLUTTER_SDK',
  };

  factory AppConfig.fromValues(Map<String, String> values) {
    if (values.keys.any((key) => !keys.contains(key))) {
      throw ArgumentError('Unknown configuration key.');
    }
    if (values['CONFIG_SCHEMA_VERSION'] != schemaVersion) {
      throw ArgumentError('Unsupported configuration schema.');
    }
    final environment = switch (values['APP_ENV']) {
      'dev' => AppEnvironment.dev,
      'prod' => AppEnvironment.prod,
      _ => throw ArgumentError('APP_ENV must be dev or prod.'),
    };
    bool boolean(String key, String fallback) =>
        switch (values[key] ?? fallback) {
          'true' => true,
          'false' => false,
          _ => throw ArgumentError('$key must be true or false.'),
        };
    int integer(String key, int fallback, int minimum, int maximum) {
      final value = int.tryParse(values[key] ?? '$fallback');
      if (value == null || value < minimum || value > maximum) {
        throw ArgumentError('$key is outside its supported range.');
      }
      return value;
    }

    final emulators = boolean('USE_FIREBASE_EMULATORS', 'false');
    if (emulators && environment == AppEnvironment.prod) {
      throw ArgumentError('Production cannot use emulators.');
    }
    final host = values['FIREBASE_EMULATOR_HOST'] ?? '127.0.0.1';
    if (!RegExp(r'^(localhost|127\.0\.0\.1|10\.0\.2\.2)$').hasMatch(host)) {
      throw ArgumentError('Use an allowlisted local emulator host.');
    }
    return AppConfig._(
      environment: environment,
      useEmulators: emulators,
      emulatorHost: host,
      authEmulatorPort: integer('AUTH_EMULATOR_PORT', 9099, 1024, 65535),
      firestoreEmulatorPort: integer(
        'FIRESTORE_EMULATOR_PORT',
        8080,
        1024,
        65535,
      ),
      saveDebounce: Duration(
        milliseconds: integer('SAVE_DEBOUNCE_MILLISECONDS', 2000, 100, 10000),
      ),
      emailCooldown: Duration(
        seconds: integer('EMAIL_COOLDOWN_SECONDS', 60, 30, 300),
      ),
      build: BuildIdentity._fromValues(values),
      product: ProjectConfiguration(
        featureFlags: FeatureFlags(
          values: {
            FeatureFlag.imputeMissingData: boolean(
              'IMPUTE_MISSING_DATA',
              'false',
            ),
            FeatureFlag.themeModeToggle: boolean('THEME_MODE_TOGGLE', 'false'),
          },
        ),
        brand: BrandConfiguration.defaults,
        uiCopy: UiCopyConfiguration.defaults,
      ),
    );
  }

  final AppEnvironment environment;
  final bool useEmulators;
  final String emulatorHost;
  final int authEmulatorPort;
  final int firestoreEmulatorPort;
  final Duration saveDebounce;
  final Duration emailCooldown;
  final ProjectConfiguration product;
  final BuildIdentity build;

  String get projectId => useEmulators
      ? localProjectId
      : switch (environment) {
          AppEnvironment.dev => 'bramwellsprecisiontestkitdev',
          AppEnvironment.prod => 'bramwells-precision-test-kit',
        };
  Uri get publicOrigin => Uri.parse(
    useEmulators
        ? 'http://127.0.0.1:7357'
        : switch (environment) {
            AppEnvironment.dev => 'https://dev.bramwelltest.com',
            AppEnvironment.prod => 'https://bramwelltest.com',
          },
  );

  void validateNativeFlavor(String? flavor, {required bool required}) {
    if ((required && flavor == null) ||
        (flavor != null && flavor != environment.name)) {
      throw StateError('Native flavor and APP_ENV disagree.');
    }
  }
}

/// Public build identity supplied by the release wrapper. Unwrapped test builds
/// are explicitly marked unknown rather than pretending to be releases.
final class BuildIdentity {
  const BuildIdentity._(this.id, this.version, this.revision, this.flutterSdk);
  static const unknown = BuildIdentity._(
    'unknown',
    '0.0.0+0',
    'unknown',
    'unknown',
  );
  final String id;
  final String version;
  final String revision;
  final String flutterSdk;

  factory BuildIdentity._fromValues(Map<String, String> values) {
    final id = values['BUILD_ID'] ?? unknown.id;
    final version = values['BUILD_VERSION'] ?? unknown.version;
    final revision = values['BUILD_REVISION'] ?? unknown.revision;
    final sdk = values['BUILD_FLUTTER_SDK'] ?? unknown.flutterSdk;
    if ((id != 'unknown' &&
            !RegExp(r'^[a-f0-9]{12}-[a-z0-9]{4,16}$').hasMatch(id)) ||
        !RegExp(r'^\d{1,6}\.\d{1,6}\.\d{1,6}\+\d{1,10}$').hasMatch(version) ||
        (revision != 'unknown' &&
            !RegExp(r'^[a-f0-9]{40}([a-f0-9]{24})?$').hasMatch(revision)) ||
        (sdk != 'unknown' &&
            !RegExp(r'^\d{1,6}\.\d{1,6}\.\d{1,6}$').hasMatch(sdk))) {
      throw ArgumentError('Invalid build identity.');
    }
    return BuildIdentity._(id, version, revision, sdk);
  }
}

/// The only compilation-declaration boundary. Restart after changing inputs.
AppConfig loadBuildConfig() => AppConfig.fromValues({
  'CONFIG_SCHEMA_VERSION': const String.fromEnvironment(
    'CONFIG_SCHEMA_VERSION',
  ),
  'APP_ENV': const String.fromEnvironment('APP_ENV'),
  'USE_FIREBASE_EMULATORS': const String.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: 'false',
  ),
  'FIREBASE_EMULATOR_HOST': const String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  ),
  'AUTH_EMULATOR_PORT': const String.fromEnvironment(
    'AUTH_EMULATOR_PORT',
    defaultValue: '9099',
  ),
  'FIRESTORE_EMULATOR_PORT': const String.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: '8080',
  ),
  'SAVE_DEBOUNCE_MILLISECONDS': const String.fromEnvironment(
    'SAVE_DEBOUNCE_MILLISECONDS',
    defaultValue: '2000',
  ),
  'EMAIL_COOLDOWN_SECONDS': const String.fromEnvironment(
    'EMAIL_COOLDOWN_SECONDS',
    defaultValue: '60',
  ),
  'IMPUTE_MISSING_DATA': const String.fromEnvironment(
    'IMPUTE_MISSING_DATA',
    defaultValue: 'false',
  ),
  'THEME_MODE_TOGGLE': const String.fromEnvironment(
    'THEME_MODE_TOGGLE',
    defaultValue: 'false',
  ),
  'BUILD_ID': const String.fromEnvironment('BUILD_ID', defaultValue: 'unknown'),
  'BUILD_VERSION': const String.fromEnvironment(
    'BUILD_VERSION',
    defaultValue: '0.0.0+0',
  ),
  'BUILD_REVISION': const String.fromEnvironment(
    'BUILD_REVISION',
    defaultValue: 'unknown',
  ),
  'BUILD_FLUTTER_SDK': const String.fromEnvironment(
    'BUILD_FLUTTER_SDK',
    defaultValue: 'unknown',
  ),
});
