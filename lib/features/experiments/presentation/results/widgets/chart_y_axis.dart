import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/chart/chart_scale.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Builds the left axis [AxisTitles] for the combined results chart.
///
/// Includes a rotated "Group Size" axis name and numeric tick labels on the inner
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
      axisNameWidget: Text(
        scale.isCompact
            ? context.l10n.aVG2SHOTGROUPSIZE
            : context.l10n.aVERAGETWOSHOTGROUPSIZE,
        style: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: scale.factorLabelFontSize,
          letterSpacing: 0,
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
            padding: scale.yTickPadding,
            child: Text(
              context.decimal(value, places: 2),
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
