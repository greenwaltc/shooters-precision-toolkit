import 'package:bramwells_precision_test_kit/features/contact/presentation/contact_page.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_background.dart';
import 'package:bramwells_precision_test_kit/shared/ui/navigation/app_page_transitions.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_configuration.dart';

void main() {
  testWidgets(
    'contact actions have labels, contrast and usable touch targets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpConfiguredWidget(
          tester,
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            builder: (_, child) => AppBackground(child: child!),
            home: const ContactPage(),
          ),
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final reducedMotion in [false, true]) {
    testWidgets('page transition respects reduced motion=$reducedMotion', (
      tester,
    ) async {
      await pumpConfiguredWidget(
        tester,
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reducedMotion),
              child: Builder(
                builder: (context) =>
                    const AppPageTransitionsBuilder().buildTransitions<void>(
                      AppPageRoute<void>(
                        builder: (_) => const SizedBox.shrink(),
                      ),
                      context,
                      const AlwaysStoppedAnimation(.5),
                      const AlwaysStoppedAnimation(0),
                      const Text('Visible route'),
                    ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Visible route'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is FadeTransition &&
              widget.opacity.value > 0 &&
              widget.opacity.value < 1,
        ),
        reducedMotion ? findsNothing : findsOneWidget,
      );
    });
  }

  testWidgets(
    'localized resources, plural messages and locale numbers stay consistent',
    (tester) async {
      String? one;
      String? several;
      String? decimal;
      await pumpConfiguredWidget(
        tester,
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              one = context.l10n.factorRunCount(1, 8);
              several = context.l10n.factorRunCount(4, 16);
              decimal = context.decimal(1234.5);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(one, '1 factor · 8 runs');
      expect(several, '4 factors · 16 runs');
      expect(decimal, '1,234.5000');
    },
  );
}
