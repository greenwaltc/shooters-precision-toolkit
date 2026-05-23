// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/chart/chart_scale.dart';
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
    this.maxWidth,
  });

  final String label;
  final Color color;
  final LegendStyle style;
  final ChartScale scale;
  final Color onSurfaceVariant;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: scale.legendIconWidth,
          height: scale.legendIconHeight,
          child: CustomPaint(
            painter: LegendPainter(color: color, style: style),
          ),
        ),
        SizedBox(width: scale.legendIconLabelGap),
        Flexible(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: onSurfaceVariant,
              fontSize: scale.axisLabelFontSize,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );

    final maxWidth = this.maxWidth;
    if (maxWidth == null) return content;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    );
  }
}
