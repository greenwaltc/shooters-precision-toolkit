import 'package:bramwells_precision_test_kit/contact/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Contact shows a placeholder without exposing an email address', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ContactPage()));
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
