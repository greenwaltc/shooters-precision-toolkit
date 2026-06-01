// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../styles/chart/chart_scale.dart';
import '../../../styles/theme_extensions/anomr_chart_theme.dart';

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
    final chartTheme =
        Theme.of(context).extension<AnomrChartTheme>() ??
        const AnomrChartTheme.standard();
    final grandMeanColor = scheme.onSurface.withValues(
      alpha: chartTheme.referenceLineOpacity,
    );
    final boundColor = scheme.error;

    final percentLabel = (detectableDiffPercent * 100).toStringAsFixed(0);
    final boundsCollapsed = (upperBound - lowerBound).abs() < 0.0000001;
    String formatYValue(double value) => value.toStringAsFixed(4);

    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: grandMean,
          color: grandMeanColor,
          strokeWidth: scale.meanLineWidth,
          label: HorizontalLineLabel(
            show: !scale.isCompact,
            alignment: Alignment.topRight,
            padding: scale.topRefLabelPadding,
            style: textTheme.bodySmall?.copyWith(
              color: grandMeanColor,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
            labelResolver: (_) =>
                boundsCollapsed ? 'Mean / ±$percentLabel%' : 'Grand mean',
          ),
        ),
        HorizontalLine(
          y: upperBound,
          color: boundColor,
          strokeWidth: scale.meanLineWidth,
          dashArray: chartTheme.boundLineDashArray,
          label: HorizontalLineLabel(
            show: !boundsCollapsed,
            alignment: Alignment.topRight,
            padding: scale.topRefLabelPadding,
            style: textTheme.bodySmall?.copyWith(
              color: boundColor,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
            labelResolver: (_) => formatYValue(upperBound),
          ),
        ),
        HorizontalLine(
          y: lowerBound,
          color: boundColor,
          strokeWidth: scale.meanLineWidth,
          dashArray: chartTheme.boundLineDashArray,
          label: HorizontalLineLabel(
            show: !boundsCollapsed,
            alignment: Alignment.bottomRight,
            padding: scale.bottomRefLabelPadding,
            style: textTheme.bodySmall?.copyWith(
              color: boundColor,
              fontWeight: FontWeight.w600,
              fontSize: scale.axisLabelFontSize,
            ),
            labelResolver: (_) => formatYValue(lowerBound),
          ),
        ),
      ],
    );
  }
}
