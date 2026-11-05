import 'dart:io';

import 'package:bramwells_precision_test_kit/app/config/site_configuration.dart';
import 'package:bramwells_precision_test_kit/app/firebase/firebase_bootstrap.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/json_object.dart';
import 'package:bramwells_precision_test_kit/shared/ui/product_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime links and web release origins agree for both projects', () {
    final config = decodeJsonObject(
      File('config/web_environments.json').readAsStringSync(),
    );
    expect(BrandConfiguration.publicSiteUrl, config['canonicalOrigin']);
    for (final value in jsonObject(config['environments']).values) {
      final environment = jsonObject(value);
      expect(
        siteUrlForFirebaseProject(environment['projectId']! as String),
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
