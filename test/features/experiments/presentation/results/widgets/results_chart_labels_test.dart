import 'dart:math' as math;

import 'package:bramwells_precision_test_kit/features/experiments/api/factor_stats.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/models/effect_status.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/models/factor_row.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/widgets/conclusion_row.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/widgets/results_chart_card.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/chart/chart_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/test_configuration.dart';

void main() {
  for (final longLabels in [false, true]) {
    testWidgets(
      'phone chart keeps full factor name and ${longLabels ? "diagonal" : "horizontal"} ticks',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final first = longLabels ? 'Touching the lands' : 'A';
        final second = longLabels ? 'Twenty thousandths off' : 'B';
        final row = FactorRow(
          index: 0,
          factor: const FactorDefinition(),
          stats: const FactorStats(
            firstMean: 1.2345,
            secondMean: 2.3456,
            firstCount: 4,
            secondCount: 4,
          ),
          color: Colors.blue,
          status: EffectStatus.notDetected,
          firstX: 0,
          secondX: 1,
          firstLabel: first,
          secondLabel: second,
          displayName: 'Seating depth from the lands',
        );
        await pumpConfiguredWidget(
          tester,
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ResultsChartCard(
                    factorRows: [row],
                    grandMean: 1.79,
                    lowerBound: 1,
                    upperBound: 3,
                    detectableDiffPercent: .4,
                    riskLevel: RiskLevel.values.first,
                    scale: ChartScale.of(context, constraints),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          expect(
            find.bySemanticsLabel(
              RegExp(
                r'Results chart\. Grand mean 1\.79\. Risk interval 1 to 3\.',
              ),
            ),
            findsOneWidget,
          );
        } finally {
          semantics.dispose();
        }
        expect(find.text('Seating depth from the lands'), findsWidgets);
        expect(find.text('F1'), findsNothing);
        expect(find.text('AVG. 2-SHOT GROUP SIZE'), findsOneWidget);
        expect(find.text('$first: 1.2345'), findsOneWidget);
        expect(find.text('$second: 2.3456'), findsOneWidget);
        final conclusion = find.byType(ConclusionRow);
        final meanLabel = find.descendant(
          of: conclusion,
          matching: find.text('$first: 1.2345'),
        );
        expect(
          tester.widget<Text>(meanLabel).style!.fontSize,
          greaterThanOrEqualTo(14),
        );
        final title = find.descendant(
          of: conclusion,
          matching: find.text(row.displayName),
        );
        expect(
          tester.widget<Text>(title).style!.fontSize,
          greaterThanOrEqualTo(16),
        );
        final rotation = tester.widget<Transform>(
          find
              .ancestor(of: find.text(second), matching: find.byType(Transform))
              .first,
        );
        expect(
          rotation.transform.storage[0],
          closeTo(longLabels ? math.sqrt1_2 : 1, .001),
        );
        expect(
          rotation.transform.storage[1],
          closeTo(longLabels ? -math.sqrt1_2 : 0, .001),
        );
        final factorBounds = _paintedBounds(
          tester,
          find.text(row.displayName).first,
        );
        for (final label in [first, second]) {
          final tickBounds = _paintedBounds(tester, find.text(label));
          expect(
            factorBounds.top - tickBounds.bottom,
            greaterThanOrEqualTo(7),
            reason: 'State ticks and factor labels need a visible gap.',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Rect _paintedBounds(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}
