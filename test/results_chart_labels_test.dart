import 'dart:math' as math;
import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/styles/chart/chart_scale.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_results/models/effect_status.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_results/models/factor_row.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_results/models/factor_stats.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_results/widgets/results_chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
        await tester.pumpWidget(
          MaterialApp(
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
        await tester.pumpAndSettle();
        expect(find.text('Seating depth from the lands'), findsWidgets);
        expect(find.text('F1'), findsNothing);
        expect(find.text('AVG. 2-SHOT GROUP SIZE'), findsOneWidget);
        expect(find.text('$first: 1.2345'), findsOneWidget);
        expect(find.text('$second: 2.3456'), findsOneWidget);
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
