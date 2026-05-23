// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/widgets.dart';

import '../layout/app_layout.dart';

/// Screen-adaptive sizing used throughout the results chart.
///
/// All measurements derive from a single [scale] factor, computed from the
/// available width. Each getter clamps independently so individual values
/// never drift to extremes even when [scale] does.
///
/// Lives under `lib/styles/` because it's part of the chart's design
/// system: tweaking it changes only sizing/typography of the chart, never
/// behavior.
class ChartScale {
  const ChartScale._({required this.scale, required this.isCompact});

  factory ChartScale.of(BuildContext context, BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final raw = width / _baseWidth;
    final clamped = raw.clamp(_minScale, _maxScale);
    return ChartScale._(
      scale: clamped,
      isCompact: width < AppLayoutMetrics.mobileBreakpoint,
    );
  }

  /// Width (in logical pixels) at which [scale] equals 1.0.
  static const double _baseWidth = 820;

  /// Minimum / maximum scale factor.
  static const double _minScale = 0.78;
  static const double _maxScale = 1.45;

  final double scale;
  final bool isCompact;

  // Layout sizes
  double get chartHeight => isCompact
      ? (360 * scale).clamp(300.0, 390.0)
      : (340 * scale).clamp(280.0, 540.0);
  double get chartOuterPadding => isCompact
      ? (14 * scale).clamp(10.0, 18.0)
      : (18 * scale).clamp(14.0, 28.0);

  // Font sizes
  double get axisLabelFontSize => isCompact
      ? (10.5 * scale).clamp(9.5, 11.5)
      : (11 * scale).clamp(10.5, 15.0);
  double get stateLabelFontSize => isCompact
      ? (11 * scale).clamp(10.0, 12.0)
      : (12 * scale).clamp(11.0, 16.0);
  double get factorLabelFontSize => isCompact
      ? (12 * scale).clamp(11.0, 13.0)
      : (13 * scale).clamp(12.0, 17.0);

  // Stroke / dot sizes
  double get dotRadius => (5.5 * scale).clamp(4.5, 8.0);
  double get dotStroke => (2.5 * scale).clamp(2.0, 3.5);
  double get lineWidth => (3 * scale).clamp(2.5, 4.5);
  double get meanLineWidth => (1.5 * scale).clamp(1.2, 2.4);

  // Axis reserves
  double get leftAxisReserve => isCompact ? 42 : (52 * scale).clamp(46.0, 72.0);
  double get yAxisNameReserve => isCompact ? 0 : (26 * scale).clamp(22.0, 36.0);

  // Bottom axis is two stacked rows: state labels on top, factor names below.
  double get stateLabelTopPad => 6.0;
  double get stateLabelMaxWidth =>
      isCompact ? 68 : (92 * scale).clamp(78.0, 130.0);
  double get factorLabelMaxWidth =>
      isCompact ? 34 : (128 * scale).clamp(96.0, 160.0);
  double get stateLabelRowHeight => isCompact
      ? stateLabelMaxWidth + stateLabelTopPad + 4
      : stateLabelFontSize + stateLabelTopPad + 6;
  double get factorLabelGap => (10 * scale).clamp(8.0, 14.0);
  double get factorLabelRowHeight => factorLabelFontSize + 6;
  double get bottomStateLabelReserve =>
      stateLabelRowHeight + factorLabelGap + factorLabelRowHeight;

  // Legend
  double get legendIconWidth => (28 * scale).clamp(24.0, 38.0);
  double get legendIconHeight => 14;
  double get legendIconLabelGap => 6;
  double get legendItemSpacing => isCompact ? 10 : 18;
  double get legendRunSpacing => isCompact ? 8 : 10;

  // Conclusion row
  double get conclusionRowFactorGap => 10;
  double get conclusionRowPillGap => 12;
  double get conclusionRowLabelGap => 2;

  /// Axis label paddings reused by the chart's axes and reference lines.
  EdgeInsets get axisNamePadding => const EdgeInsets.only(bottom: 6);
  EdgeInsets get yTickPadding => const EdgeInsets.only(right: 6);
  EdgeInsets get topRefLabelPadding =>
      const EdgeInsets.only(right: 6, bottom: 2);
  EdgeInsets get bottomRefLabelPadding =>
      const EdgeInsets.only(right: 6, top: 2);
}
