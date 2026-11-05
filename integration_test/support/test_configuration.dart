import 'dart:math';

import 'package:bramwells_precision_test_kit/app/config/app_config.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/clipboard_events.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/external_links.dart';
import 'package:bramwells_precision_test_kit/shared/ui/emulator_presentation.dart';
import 'package:bramwells_precision_test_kit/shared/ui/product_configuration.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

AppConfig testConfig({String environment = 'dev', bool emulators = false}) =>
    AppConfig.fromValues({
      'CONFIG_SCHEMA_VERSION': '1',
      'APP_ENV': environment,
      'USE_FIREBASE_EMULATORS': '$emulators',
    });

Future<void> pumpConfiguredWidget(WidgetTester tester, Widget widget) =>
    tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppConfig>.value(value: testConfig()),
          Provider<ClipboardEvents>.value(value: const _NoClipboardEvents()),
          Provider<ExternalLinks>.value(value: const _NoExternalLinks()),
          Provider<EmulatorPresentation>.value(
            value: const EmulatorPresentation(enabled: false),
          ),
          Provider<Random>(create: (_) => Random(4729)),
        ],
        child: ProjectConfigurationScope(
          configuration: ProjectConfiguration.defaults,
          child: widget,
        ),
      ),
    );

final class _NoExternalLinks implements ExternalLinks {
  const _NoExternalLinks();
  @override
  Future<bool> open(Uri uri) async => false;
}

final class _NoClipboardEvents implements ClipboardEvents {
  const _NoClipboardEvents();
  @override
  void Function() register({
    required bool Function() acceptsPaste,
    required String? Function() copyText,
    required void Function(String) pasteText,
  }) => () {};
}
