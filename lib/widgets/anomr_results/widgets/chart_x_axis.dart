// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../styles/chart/chart_layout.dart';
import '../../../styles/chart/chart_scale.dart';
import '../services/factor_row_locator.dart';

/// Builds the bottom axis [AxisTitles] for the combined results chart.
///
/// Lays out two stacked rows on the X-axis:
///   * State labels at integer positions, on the row closest to the axis.
///   * Factor names at half-integer (factor midpoint) positions, on a second
///     row below the state labels with [ChartScale.factorLabelGap] between.
class ChartXAxis {
  const ChartXAxis._();

  static AxisTitles build({
    required BuildContext context,
    required FactorRowLocator locator,
    required ChartScale scale,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        // Half-segment interval so fl_chart visits both state ticks
        // (integer) and factor midpoints (half-integer).
        interval: ChartLayout.segmentSpan / 2,
        reservedSize: scale.bottomStateLabelReserve,
        getTitlesWidget: (value, _) {
          final factorMatch = locator.factorAtMidpoint(value);
          if (factorMatch != null) {
            return Padding(
              padding: EdgeInsets.only(
                top: scale.stateLabelRowHeight + scale.factorLabelGap,
              ),
              child: Text(
                factorMatch.displayName,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: scale.factorLabelFontSize,
                  color: scheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            );
          }
          final stateLabel = locator.stateLabelAt(value);
          if (stateLabel != null) {
            return Padding(
              padding: EdgeInsets.only(top: scale.stateLabelTopPad),
              child: Text(
                stateLabel,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: scale.stateLabelFontSize,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
