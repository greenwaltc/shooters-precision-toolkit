import 'package:flutter/widgets.dart';

/// Screen-adaptive sizing used throughout the results chart.
///
/// All measurements derive from a single [scale] factor, computed from the
/// available width. Each getter clamps independently so individual values
/// never drift to extremes even when [scale] does.
class ChartScale {
  const ChartScale._(this.scale);

  factory ChartScale.of(BuildContext context, BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final raw = width / 820;
    final clamped = raw.clamp(0.78, 1.45);
    return ChartScale._(clamped);
  }

  final double scale;

  // Layout sizes
  double get chartHeight => (340 * scale).clamp(280.0, 540.0);
  double get chartOuterPadding => (18 * scale).clamp(14.0, 28.0);

  // Font sizes
  double get axisLabelFontSize => (11 * scale).clamp(10.5, 15.0);
  double get stateLabelFontSize => (12 * scale).clamp(11.0, 16.0);
  double get factorLabelFontSize => (13 * scale).clamp(12.0, 17.0);

  // Stroke / dot sizes
  double get dotRadius => (5.5 * scale).clamp(4.5, 8.0);
  double get dotStroke => (2.5 * scale).clamp(2.0, 3.5);
  double get lineWidth => (3 * scale).clamp(2.5, 4.5);
  double get meanLineWidth => (1.5 * scale).clamp(1.2, 2.4);

  // Axis reserves
  double get leftAxisReserve => (52 * scale).clamp(46.0, 72.0);
  double get yAxisNameReserve => (26 * scale).clamp(22.0, 36.0);

  // Bottom axis is two stacked rows: state labels on top, factor names below.
  double get stateLabelTopPad => 6.0;
  double get stateLabelRowHeight =>
      stateLabelFontSize + stateLabelTopPad + 6;
  double get factorLabelGap => (10 * scale).clamp(8.0, 14.0);
  double get factorLabelRowHeight => factorLabelFontSize + 6;
  double get bottomStateLabelReserve =>
      stateLabelRowHeight + factorLabelGap + factorLabelRowHeight;

  // Legend
  double get legendIconWidth => (28 * scale).clamp(24.0, 38.0);
}
