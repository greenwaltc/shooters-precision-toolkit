import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shooters_precision_toolkit/main.dart';

void main() {
  testWidgets('ANOMR project form renders default inputs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text("Shooter's Precision Toolkit"), findsOneWidget);
    expect(find.text('New ANOMR Project'), findsOneWidget);
    expect(find.text('Project Name'), findsOneWidget);
    expect(
      find.text('Choose the Structure of Your Experiment'),
      findsOneWidget,
    );
    expect(find.text('Simple A vs B Comparison'), findsOneWidget);
    expect(find.text('Impute missing data'), findsOneWidget);
    expect(
      find.text('8 total samples in 2 groups of 4 ranges each'),
      findsOneWidget,
    );
  });

  testWidgets('ANOMR project form validates required text fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Project name is required.'), findsOneWidget);
    expect(find.text('Factor name is required.'), findsWidgets);
    expect(find.text('Factor state is required.'), findsWidgets);
  });

  testWidgets('ANOMR project form updates dynamic factor and sample sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Test How Three Factors Influence A'));
    await tester.pumpAndSettle();

    expect(find.text('Factor 3'), findsOneWidget);
    expect(
      find.text('16 total samples in 8 groups of 2 ranges each'),
      findsOneWidget,
    );
  });

  testWidgets('ANOMR project form submits to matrix with shared model', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Range Test');
    await tester.enterText(fields.at(1), 'Primer');
    await tester.enterText(fields.at(2), 'Standard');
    await tester.enterText(fields.at(3), 'Magnum');
    await tester.enterText(fields.at(4), 'Powder');
    await tester.enterText(fields.at(5), 'Light');
    await tester.enterText(fields.at(6), 'Heavy');

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Range Test'), findsOneWidget);
  });
}
