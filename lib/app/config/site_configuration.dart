import 'app_config.dart';

/// Exact Firebase identity-to-origin mapping. Unknown identities fail closed.
String siteUrlForFirebaseProject(String projectId) {
  for (final environment in AppEnvironment.values) {
    final config = AppConfig.fromValues({
      'CONFIG_SCHEMA_VERSION': '1',
      'APP_ENV': environment.name,
    });
    if (config.projectId == projectId) {
      return config.publicOrigin.toString();
    }
  }
  if (projectId == AppConfig.localProjectId) {
    return AppConfig.fromValues({
      'CONFIG_SCHEMA_VERSION': '1',
      'APP_ENV': 'dev',
      'USE_FIREBASE_EMULATORS': 'true',
    }).publicOrigin.toString();
  }
  throw StateError('Unknown Firebase project.');
}
