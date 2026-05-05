import 'package:flutter/material.dart';

import '../models/effect_status.dart';
import '../models/factor_row.dart';
import '../theme/chart_scale.dart';
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
        color: row.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: row.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: scale.legendIconWidth,
            height: 14,
            child: CustomPaint(
              painter: LegendPainter(
                color: row.color,
                style: LegendStyle.solidDots,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
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
          const SizedBox(width: 12),
          _StatusPill(
            label: row.status.label,
            color: statusColor,
            icon: statusIcon,
            scale: scale,
            textTheme: textTheme,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
    required this.scale,
    required this.textTheme,
  });

  final String label;
  final Color color;
  final IconData icon;
  final ChartScale scale;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scale.scale).clamp(8.0, 14.0),
        vertical: (6 * scale.scale).clamp(5.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: scale.stateLabelFontSize + 4, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: scale.axisLabelFontSize + 1,
            ),
          ),
        ],
      ),
    );
  }
}
