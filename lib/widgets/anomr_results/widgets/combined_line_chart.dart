import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/factor_row.dart';
import '../services/factor_row_locator.dart';
import '../theme/chart_layout.dart';
import '../theme/chart_scale.dart';
import 'chart_reference_lines.dart';
import 'chart_x_axis.dart';
import 'chart_y_axis.dart';
import 'chart_y_range.dart';

/// Single fl_chart `LineChart` rendering one colored line segment per factor
/// over a shared grand-mean / risk-bound reference frame.
class CombinedLineChart extends StatelessWidget {
  const CombinedLineChart({
    super.key,
    required this.factorRows,
    required this.grandMean,
    required this.lowerBound,
    required this.upperBound,
    required this.detectableDiffPercent,
    required this.scale,
  });

  final List<FactorRow> factorRows;
  final double grandMean;
  final double lowerBound;
  final double upperBound;
  final double detectableDiffPercent;
  final ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locator = FactorRowLocator(factorRows);
    final lastSecondX = factorRows.isEmpty
        ? ChartLayout.segmentSpan
        : factorRows.last.secondX;
    final minX = -ChartLayout.edgePad;
    final maxX = lastSecondX + ChartLayout.edgePad;

    final yRange = ChartYRange.compute([
      grandMean,
      upperBound,
      lowerBound,
      for (final row in factorRows) ...[
        if (row.stats.hasFirst) row.stats.firstMean,
        if (row.stats.hasSecond) row.stats.secondMean,
      ],
    ]);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: yRange.min,
        maxY: yRange.max,
        clipData: const FlClipData.all(),
        lineTouchData: _tooltip(context, locator),
        gridData: _grid(context, yRange),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: scheme.outline),
            left: BorderSide(color: scheme.outline),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: ChartXAxis.build(
            context: context,
            locator: locator,
            scale: scale,
          ),
          leftTitles: ChartYAxis.build(context: context, scale: scale),
        ),
        extraLinesData: ChartReferenceLines.build(
          context: context,
          scale: scale,
          grandMean: grandMean,
          lowerBound: lowerBound,
          upperBound: upperBound,
          detectableDiffPercent: detectableDiffPercent,
        ),
        lineBarsData: _lineBars(),
      ),
    );
  }

  LineTouchData _tooltip(BuildContext context, FactorRowLocator locator) {
    final scheme = Theme.of(context).colorScheme;
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => scheme.inverseSurface,
        getTooltipItems: (spots) => spots.map((spot) {
          final match = locator.nearestFactor(spot.x);
          final label = match == null
              ? spot.y.toStringAsFixed(4)
              : '${match.displayName}\n'
                    '${locator.stateLabelNearest(spot.x, match)}: '
                    '${spot.y.toStringAsFixed(4)}';
          return LineTooltipItem(
            label,
            TextStyle(
              color: scheme.onInverseSurface,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
          );
        }).toList(),
      ),
    );
  }

  FlGridData _grid(BuildContext context, ChartYRangeValues yRange) {
    final scheme = Theme.of(context).colorScheme;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: ((yRange.max - yRange.min) / 4).abs(),
      getDrawingHorizontalLine: (_) => FlLine(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        strokeWidth: 1,
        dashArray: const [2, 4],
      ),
    );
  }

  List<LineChartBarData> _lineBars() {
    return [
      for (final row in factorRows)
        if (row.stats.hasBoth)
          LineChartBarData(
            spots: [
              FlSpot(row.firstX, row.stats.firstMean),
              FlSpot(row.secondX, row.stats.secondMean),
            ],
            isCurved: false,
            color: row.color,
            barWidth: scale.lineWidth,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: scale.dotRadius,
                color: row.color,
                strokeWidth: scale.dotStroke,
                strokeColor: Colors.white,
              ),
            ),
          ),
    ];
  }
}
