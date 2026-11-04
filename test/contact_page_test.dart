import 'package:bramwells_precision_test_kit/contact/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Contact works without Turnstile configuration', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ContactPage()));
    expect(find.text('Contact Denton Bramwell'), findsOneWidget);
    expect(find.text('denton@tutanota.com'), findsNothing);
    await tester.tap(find.text('Reveal email address'));
    await tester.pumpAndSettle();
    expect(find.text('denton@tutanota.com'), findsOneWidget);
    expect(find.text('Email Denton Bramwell'), findsOneWidget);
    expect(
      find.textContaining('Engineered by Cameron Greenwalt'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
