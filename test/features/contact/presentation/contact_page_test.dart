import 'package:bramwells_precision_test_kit/features/contact/presentation/contact_page.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_configuration.dart';

void main() {
  testWidgets('Contact shows a placeholder without exposing an email address', (
    tester,
  ) async {
    await pumpConfiguredWidget(
      tester,
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ContactPage(),
      ),
    );
    expect(find.text('Contact Denton Bramwell'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('contact form'), findsOneWidget);
    expect(find.text('Reveal email address'), findsNothing);
    expect(find.text('Email Denton Bramwell'), findsNothing);
    expect(
      find.textContaining('Engineered by Cameron Greenwalt'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
