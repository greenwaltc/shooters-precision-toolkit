import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/chart_scale.dart';

/// Builds the [ExtraLinesData] containing the grand-mean line and the
/// upper/lower detectable-difference bound lines.
class ChartReferenceLines {
  const ChartReferenceLines._();

  static ExtraLinesData build({
    required BuildContext context,
    required ChartScale scale,
    required double grandMean,
    required double lowerBound,
    required double upperBound,
    required double detectableDiffPercent,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grandMeanColor = scheme.onSurface.withValues(alpha: 0.6);
    final boundColor = scheme.error;

    final percentLabel = (detectableDiffPercent * 100).toStringAsFixed(0);

    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: grandMean,
          color: grandMeanColor,
          strokeWidth: scale.meanLineWidth,
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            style: textTheme.bodySmall?.copyWith(
              color: grandMeanColor,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
            labelResolver: (_) => 'Grand mean',
          ),
        ),
        HorizontalLine(
          y: upperBound,
          color: boundColor,
          strokeWidth: scale.meanLineWidth,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            style: textTheme.bodySmall?.copyWith(
              color: boundColor,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
            labelResolver: (_) => '+$percentLabel%',
          ),
        ),
        HorizontalLine(
          y: lowerBound,
          color: boundColor,
          strokeWidth: scale.meanLineWidth,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.only(right: 6, top: 2),
            style: textTheme.bodySmall?.copyWith(
              color: boundColor,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
            labelResolver: (_) => '-$percentLabel%',
          ),
        ),
      ],
    );
  }
}
