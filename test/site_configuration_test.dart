import 'dart:convert';
import 'dart:io';

import 'package:bramwells_precision_test_kit/config/project_configuration.dart';
import 'package:bramwells_precision_test_kit/config/site_configuration.dart';
import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime links and web release origins agree for both projects', () {
    final config = jsonDecode(
      File('config/web_environments.json').readAsStringSync(),
    );
    expect(BrandConfiguration.publicSiteUrl, config['canonicalOrigin']);
    for (final environment in (config['environments'] as Map).values) {
      expect(
        siteUrlForFirebaseProject(environment['projectId']),
        environment['publicOrigin'],
      );
    }
    expect(
      siteUrlForFirebaseProject(localFirebaseProjectId),
      'http://127.0.0.1:7357',
    );
    expect(
      () => siteUrlForFirebaseProject('unknown-project'),
      throwsStateError,
    );
  });
}
