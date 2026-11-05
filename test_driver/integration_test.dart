import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? arguments]) async {
        if (!RegExp(r'^[a-z-]+$').hasMatch(name)) {
          return false;
        }
        final size = (Platform.environment['BROWSER_DIMENSION'] ?? '1600x1024')
            .replaceAll(RegExp(r'[^0-9x]'), '');
        final directory = Directory('build/test-results/screenshots/$size');
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
);
