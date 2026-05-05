// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../styles/tokens/app_colors.dart';

/// Visual style of a [LegendPainter] indicator.
enum LegendStyle { solid, dashed, solidDots }

/// Paints a thin horizontal indicator (solid line, dashed line, or solid
/// line with a dot at each end) used by legend chips and conclusion rows.
class LegendPainter extends CustomPainter {
  LegendPainter({required this.color, required this.style});

  final Color color;
  final LegendStyle style;

  static const double _strokeWidth = 2;
  static const double _dashLength = 4;
  static const double _dashGap = 3;
  static const double _dotRadius = 4;
  static const double _dotInset = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    if (style == LegendStyle.dashed) {
      var x = 0.0;
      while (x < size.width) {
        final end = math.min(x + _dashLength, size.width);
        canvas.drawLine(Offset(x, midY), Offset(end, midY), paint);
        x = end + _dashGap;
      }
    } else {
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    }

    if (style == LegendStyle.solidDots) {
      final dotPaint = Paint()..color = color;
      final strokePaint = Paint()
        ..color = AppColors.chartDotOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth;
      for (final dx in [_dotInset, size.width - _dotInset]) {
        canvas.drawCircle(Offset(dx, midY), _dotRadius, dotPaint);
        canvas.drawCircle(Offset(dx, midY), _dotRadius, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LegendPainter old) {
    return old.color != color || old.style != style;
  }
}
