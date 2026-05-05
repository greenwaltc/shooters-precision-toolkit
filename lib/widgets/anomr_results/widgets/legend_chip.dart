import 'package:flutter/material.dart';

import '../theme/chart_scale.dart';
import 'legend_painter.dart';

/// A single legend entry: small line indicator plus a label.
class LegendChip extends StatelessWidget {
  const LegendChip({
    super.key,
    required this.label,
    required this.color,
    required this.style,
    required this.scale,
    required this.onSurfaceVariant,
  });

  final String label;
  final Color color;
  final LegendStyle style;
  final ChartScale scale;
  final Color onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: scale.legendIconWidth,
          height: 14,
          child: CustomPaint(
            painter: LegendPainter(color: color, style: style),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
            fontSize: scale.axisLabelFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
