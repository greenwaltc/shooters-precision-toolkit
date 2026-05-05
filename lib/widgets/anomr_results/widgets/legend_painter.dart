import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual style of a [LegendPainter] indicator.
enum LegendStyle { solid, dashed, solidDots }

/// Paints a thin horizontal indicator (solid line, dashed line, or solid
/// line with a dot at each end) used by legend chips and conclusion rows.
class LegendPainter extends CustomPainter {
  LegendPainter({required this.color, required this.style});

  final Color color;
  final LegendStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    if (style == LegendStyle.dashed) {
      const dash = 4.0;
      const gap = 3.0;
      var x = 0.0;
      while (x < size.width) {
        final end = math.min(x + dash, size.width);
        canvas.drawLine(Offset(x, midY), Offset(end, midY), paint);
        x = end + gap;
      }
    } else {
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    }

    if (style == LegendStyle.solidDots) {
      final dotPaint = Paint()..color = color;
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final dx in [3.0, size.width - 3.0]) {
        canvas.drawCircle(Offset(dx, midY), 4, dotPaint);
        canvas.drawCircle(Offset(dx, midY), 4, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LegendPainter old) {
    return old.color != color || old.style != style;
  }
}
