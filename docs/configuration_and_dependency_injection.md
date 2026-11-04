# Application configuration and dependency injection

Status and requirement language: [engineering standards](README.md).

## Configuration contract

Configuration selects deployment behavior; dependency injection supplies the
objects implementing that behavior. Both MUST be explicit and testable. Read raw
configuration in one boundary, validate it, construct immutable typed values, and
inject those values or their narrow projections into consumers.

Feature code MUST NOT read compilation declarations, environment files, mutable
global settings, or a service locator directly. Constructors MUST expose required
collaborators. Flutter documents dependency injection as a way to separate
construction from consumption in its
[dependency injection guide](https://docs.flutter.dev/app-architecture/case-study/dependency-injection).

| Category | Source and lifetime | Rules |
| --- | --- | --- |
| Deployment identity | Validated build inputs; fixed for the artifact | Environment, API origin, native app identity, public service identifiers. Required values have no implicit production fallback. |
| Native build settings | Android build variants / Apple schemes and configurations | Match the selected environment; signing material stays in the release system. |
| Runtime feature policy | Typed remote response with version and expiry | Allowlisted keys only; safe defaults and explicit refresh behavior. |
| User preferences | Local/account repository | Typed, migrated, independently resettable; never override environment or permissions. |
| Session credentials | Authentication flow and appropriate platform storage | Never part of build configuration, source control, or logs. |
| Server secrets | Server-side secret store | Never delivered to the Flutter client. |

Every configuration field MUST document its type, allowed range, source, default
or required status, owner, sensitivity, and when changes take effect. Reject
unknown environments, malformed values, and incompatible schema versions before
creating external clients. Use executable validation, not assertions.

An app bundle is inspectable. `--dart-define`, asset JSON, `.env` files, and
obfuscation cannot conceal a private key or server credential. Public client
identifiers may be bundled when designed for that use, with appropriate service
restrictions. See [Flutter obfuscation limitations](https://docs.flutter.dev/deployment/obfuscate).

## Build-time injection

Use compilation declarations for a modest set of immutable public settings.
Flutter accepts `--dart-define=KEY=value`. These declarations differ from operating
system environment variables; exporting a shell variable does not automatically
make it a Dart declaration. See
[Dart compilation environments](https://dart.dev/libraries/core/environment-declarations).

Read them through constant `String.fromEnvironment` calls at the configuration
boundary. Constant invocation is required for portable behavior across compiled
targets; see [String.fromEnvironment](https://api.dart.dev/dart-core/String/String.fromEnvironment.html).
Parse booleans and numbers explicitly when invalid text must fail instead of
silently taking a default.

The following self-contained Dart example can become `lib/app/config/app_config.dart`.
The reserved example hosts MUST be replaced with the actual environment allowlist
before adoption. This example requires HTTPS in every environment.

```dart
enum AppEnvironment { development, staging, production }

final class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.apiBaseUri,
    required this.requestTimeout,
    required this.telemetryEnabled,
  });

  factory AppConfig.fromValues(Map<String, String> values) {
    const keys = {
      'CONFIG_SCHEMA_VERSION',
      'APP_ENV',
      'API_BASE_URL',
      'REQUEST_TIMEOUT_SECONDS',
      'TELEMETRY_ENABLED',
    };
    if (values.keys.any((key) => !keys.contains(key))) {
      throw ArgumentError('Unknown configuration key.');
    }
    if (values['CONFIG_SCHEMA_VERSION'] != '1') {
      throw ArgumentError('CONFIG_SCHEMA_VERSION must be 1.');
    }

    final environment = switch (values['APP_ENV']) {
      'development' => AppEnvironment.development,
      'staging' => AppEnvironment.staging,
      'production' => AppEnvironment.production,
      _ => throw ArgumentError('APP_ENV is missing or invalid.'),
    };
    final expectedHost = switch (environment) {
      AppEnvironment.development => 'api.dev.example.com',
      AppEnvironment.staging => 'api.staging.example.com',
      AppEnvironment.production => 'api.example.com',
    };
    final uri = Uri.tryParse(values['API_BASE_URL'] ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != expectedHost ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.path.endsWith('/')) {
      throw ArgumentError('API_BASE_URL is invalid for APP_ENV.');
    }

    final timeoutSeconds = int.tryParse(
      values['REQUEST_TIMEOUT_SECONDS'] ?? '15',
    );
    if (timeoutSeconds == null || timeoutSeconds < 1 || timeoutSeconds > 60) {
      throw ArgumentError('REQUEST_TIMEOUT_SECONDS must be from 1 to 60.');
    }
    final telemetryEnabled = switch (values['TELEMETRY_ENABLED'] ?? 'false') {
      'true' => true,
      'false' => false,
      _ => throw ArgumentError('TELEMETRY_ENABLED must be true or false.'),
    };

    return AppConfig._(
      environment: environment,
      apiBaseUri: uri,
      requestTimeout: Duration(seconds: timeoutSeconds),
      telemetryEnabled: telemetryEnabled,
    );
  }

  final AppEnvironment environment;
  final Uri apiBaseUri;
  final Duration requestTimeout;
  final bool telemetryEnabled;
}

AppConfig loadBuildConfig() => AppConfig.fromValues({
  'CONFIG_SCHEMA_VERSION': const String.fromEnvironment(
    'CONFIG_SCHEMA_VERSION',
  ),
  'APP_ENV': const String.fromEnvironment('APP_ENV'),
  'API_BASE_URL': const String.fromEnvironment('API_BASE_URL'),
  'REQUEST_TIMEOUT_SECONDS': const String.fromEnvironment(
    'REQUEST_TIMEOUT_SECONDS',
    defaultValue: '15',
  ),
  'TELEMETRY_ENABLED': const String.fromEnvironment(
    'TELEMETRY_ENABLED',
    defaultValue: 'false',
  ),
});
```

Example field contract: schema, environment, and URL are required; request timeout
defaults to 15 seconds within 1–60; telemetry defaults to disabled. All five are
public build inputs, owned by the application/bootstrap layer and immutable for a
running artifact. Enabling telemetry only makes collection eligible; applicable
user consent and product privacy policy still govern collection.

The loader enumerates known declarations. CI MUST also validate the full input
manifest so a misspelled or unused build key cannot be silently ignored.

Example command after adopting the loader:

```sh
flutter run \
  --dart-define=CONFIG_SCHEMA_VERSION=1 \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=https://api.dev.example.com/v1/
```

For many settings, use a reviewed non-secret JSON manifest and
`--dart-define-from-file=config/staging.json` on the pinned Flutter CLI. The file
must contain the same flat keys and string values as the parser. Validate the file
before invoking Flutter. Choose one source for each key; the build wrapper MUST
reject duplicates across files and individual flags rather than depending on
implicit override order. Commit public environment manifests or sanitized example
manifests; ignore developer-specific local values. Record the manifest checksum
with the release artifact.

An example `config/staging.json` is:

```json
{
  "CONFIG_SCHEMA_VERSION": "1",
  "APP_ENV": "staging",
  "API_BASE_URL": "https://api.staging.example.com/v1/",
  "REQUEST_TIMEOUT_SECONDS": "15",
  "TELEMETRY_ENABLED": "false"
}
```

Build-time changes require a new build/restart; hot reload is not a configuration
deployment mechanism. Do not derive deployment identity from `kReleaseMode`:
staging can also be built in release mode.

## Native flavors and web builds

Use native flavors when environments need different application IDs, display
names, icons, entitlements, or service resources. Set up
[Android product flavors](https://docs.flutter.dev/deployment/flavors) and
[Apple schemes/configurations](https://docs.flutter.dev/deployment/flavors-ios)
explicitly. A Dart declaration does not create these native variants.

For example, after defining the `staging` Android flavor and the manifest:

```sh
flutter build appbundle --release --flavor staging \
  --dart-define-from-file=config/staging.json
```

CI MUST ensure that flavor/scheme, Dart environment, endpoint allowlist, native
service resources, signing selection, and deployment destination agree. On
builds using native flavors, compare Flutter's `appFlavor` to
`config.environment.name` during bootstrap and reject mismatches; artifact
validation must also inspect native resources. Keep environment names consistent
across these systems.

Web uses its own build/deployment configuration. Do not assume Android/iOS flavor
support applies to web. A typical separate staging build is:

```sh
flutter build web --release \
  --dart-define-from-file=config/staging.json
```

If a single web artifact must move between environments, define a separate,
validated runtime bootstrap manifest and its loading/cache policy in an ADR.
Do not pretend compilation declarations can be changed after compilation.

## Composition root and lifetimes

The composition root MUST validate configuration, initialize necessary platform
bindings, create external adapters, wire repositories, and supply presentation
dependencies before starting the relevant feature. Initialization failures need a
safe error surface and redacted diagnostics, never a fallback to production.

The following wiring sketch uses illustrative application types:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = loadBuildConfig();
  final api = ApiClient(
    baseUri: config.apiBaseUri,
    timeout: config.requestTimeout,
  );
  final repository = ApiCatalogRepository(api: api);
  runApp(MyApp(catalogRepository: repository));
}
```

The app root owns `api`; a route factory injects `repository` into each route's
view model. Add the chosen error-reporting/bootstrap boundary around this sketch
and explicit cleanup for partial initialization and controlled shutdown. Mobile
process termination is not a reliable opportunity to flush essential data.

| Scope | Typical contents | Disposal responsibility |
| --- | --- | --- |
| Application | Configuration, shared client, public catalog repository | Root owner |
| Session | User-specific repositories, subscriptions, sensitive caches | Session owner, including sign-out and account switch |
| Route/widget | View model, animation/text controllers | Route or widget owner |
| Operation | Cancellation handle, temporary stream/file | Caller, including failure paths |

Constructor injection is the default. A UI provider/container MAY distribute and
own dependencies, but consumers outside the UI must receive ordinary typed
objects. Never hide a required dependency behind an optional constructor parameter
that creates a real client. Do not initialize the same shared SDK once per widget.
Supply only the settings a consumer needs rather than passing all configuration
through every layer.

## Runtime policy and verification

Runtime overrides MUST use a separate typed model. For an allowlisted flag, apply
a valid current remote value, otherwise an unexpired validated last-known value,
otherwise the shipped safe default. Record this precedence and expiry per field.
Reject incompatible responses atomically. Specify whether refresh affects the
current screen, next operation, or next launch; never mutate an in-flight
operation's policy unexpectedly.

Runtime flags and user preferences MUST NOT override deployment identity,
credentials, authorization, or transport security. Feature flags require an owner,
removal date, and tests for both states. A client-side flag cannot grant access.

Tests MUST construct `AppConfig.fromValues` directly, inject fakes, and avoid
global overrides. Cover each environment, missing required keys, misspellings,
invalid booleans/ranges/URLs, cross-environment hosts, native mismatch, and runtime
fallbacks. Add an assembled bootstrap smoke test per supported environment.
See [testing standards](testing_standards.md).
