import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/chart_scale.dart';

/// Builds the left axis [AxisTitles] for the combined results chart.
///
/// Includes a rotated "Range" axis name and numeric tick labels on the inner
/// side; min/max ticks are suppressed so they don't visually collide with
/// the chart border.
class ChartYAxis {
  const ChartYAxis._();

  static AxisTitles build({
    required BuildContext context,
    required ChartScale scale,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AxisTitles(
      axisNameSize: scale.yAxisNameReserve,
      axisNameWidget: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          'Range',
          style: textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: scale.factorLabelFontSize,
            letterSpacing: 0.4,
          ),
        ),
      ),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: scale.leftAxisReserve,
        getTitlesWidget: (value, meta) {
          if (value == meta.min || value == meta.max) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              value.toStringAsFixed(2),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: scale.axisLabelFontSize,
              ),
              textAlign: TextAlign.right,
            ),
          );
        },
      ),
    );
  }
}
