// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/chart/chart_scale.dart';
import '../../../styles/components/status_pill.dart';
import '../../../styles/tokens/app_opacity.dart';
import '../../../styles/tokens/app_radius.dart';
import '../models/effect_status.dart';
import '../models/factor_row.dart';
import 'legend_painter.dart';

/// Single per-factor conclusion row: colored line indicator + factor name &
/// state transition + status pill.
class ConclusionRow extends StatelessWidget {
  const ConclusionRow({super.key, required this.row, required this.scale});

  final FactorRow row;
  final ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (statusColor, statusIcon) = _statusVisuals(scheme, row.status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (12 * scale.scale).clamp(10.0, 18.0),
        vertical: (10 * scale.scale).clamp(8.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: row.color.withValues(alpha: AppOpacity.rowFill),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: row.color.withValues(alpha: AppOpacity.rowBorder),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: scale.legendIconWidth,
            height: scale.legendIconHeight,
            child: CustomPaint(
              painter: LegendPainter(
                color: row.color,
                style: LegendStyle.solidDots,
              ),
            ),
          ),
          SizedBox(width: scale.conclusionRowFactorGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: scale.stateLabelFontSize + 1,
                  ),
                ),
                SizedBox(height: scale.conclusionRowLabelGap),
                Text(
                  '${row.firstLabel} → ${row.secondLabel}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: scale.axisLabelFontSize,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: scale.conclusionRowPillGap),
          StatusPill(
            label: row.status.label,
            color: statusColor,
            icon: statusIcon,
            scale: scale.scale,
            iconSize: scale.stateLabelFontSize + 4,
            fontSize: scale.axisLabelFontSize + 1,
          ),
        ],
      ),
    );
  }

  (Color, IconData) _statusVisuals(ColorScheme scheme, EffectStatus status) {
    switch (status) {
      case EffectStatus.significant:
        return (scheme.error, Icons.warning_amber_rounded);
      case EffectStatus.notDetected:
        return (scheme.primary, Icons.check_circle_outline);
      case EffectStatus.marginal:
        return (scheme.tertiary, Icons.info_outline);
      case EffectStatus.insufficient:
        return (scheme.onSurfaceVariant, Icons.help_outline);
    }
  }
}
