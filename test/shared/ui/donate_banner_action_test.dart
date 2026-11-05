import 'dart:ui' show PointerDeviceKind;

import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_bar_actions.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/app_design.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/app_theme.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/layout/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_configuration.dart';

Future<void> _pumpBanner(WidgetTester tester) => pumpConfiguredWidget(
  tester,
  MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          actions: AppBarActionBar.build(
            context,
            layout: AppLayoutMetrics.of(context),
            hasLeading: true,
            hasTitleStatus: true,
            items: [
              AppBarActionBar.instructions(context),
              AppBarActionBar.donations(context),
              AppBarActionBar.contact(context),
              AppBarActionItem(
                label: 'Projects',
                icon: Icons.home_outlined,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('Donate is the first inline action on a wide banner', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpBanner(tester);
    final controls = [
      find.widgetWithText(FilledButton, 'DONATE'),
      find.widgetWithText(FilledButton, 'Instructions'),
      find.widgetWithText(FilledButton, 'Contact'),
      find.byIcon(Icons.home_outlined),
    ].map(tester.getRect).toList();
    for (var index = 1; index < controls.length; index++) {
      expect(
        controls[index].left - controls[index - 1].right,
        AppDesign.appBarActionGap,
      );
    }
    expect(find.byTooltip('Menu'), findsNothing);
  });

  testWidgets('Donate stays inline until the banner cannot fit it', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpBanner(tester);

    final donate = find.widgetWithText(FilledButton, 'DONATE');
    expect(donate, findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Instructions'), findsNothing);
    expect(
      tester.getTopLeft(find.byIcon(Icons.menu)).dx -
          tester.getTopRight(donate).dx,
      AppDesign.appBarActionGap,
    );

    tester.view.physicalSize = const Size(280, 653);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pump();
    expect(donate, findsNothing);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final labels = find.descendant(
      of: find.byType(PopupMenuItem<AppBarActionItem>),
      matching: find.byType(Text),
    );
    expect(tester.widgetList<Text>(labels).map((label) => label.data), [
      'Donate',
      'Instructions',
      'Contact',
      'Projects',
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets('Donate gradient honors reduced motion=$reduced', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpBanner(tester);
      final ink = find.descendant(
        of: find.widgetWithText(FilledButton, 'DONATE'),
        matching: find.byType(Ink),
      );
      LinearGradient gradient() =>
          (tester.widget<Ink>(ink).decoration! as BoxDecoration).gradient!
              as LinearGradient;

      final first = gradient();
      final start = first.begin as Alignment;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(ink));
      await tester.pump();
      if (!reduced) {
        await tester.pump(AppDesign.donateGradientDuration ~/ 2);
        final mid = gradient().begin as Alignment;
        expect(mid.x, inExclusiveRange(start.x - 2, start.x));
        expect(mid.y, inExclusiveRange(start.y - 2, start.y));
        expect(gradient().colors[2], isNot(first.colors[2]));
        await tester.pump(AppDesign.donateGradientDuration);
      }
      expect(gradient().begin, Alignment(start.x - 2, start.y - 2));
      expect(gradient().colors[2], first.colors[2]);
    });
  }
}
