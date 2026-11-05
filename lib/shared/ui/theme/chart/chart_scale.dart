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
  const ChartScale._({
    required this.scale,
    required this.isCompact,
    required this.textScale,
    this.desktopChartHeight,
  });

  /// Computes sizing from the chart's available width, viewport, and user text
  /// scale.
  factory ChartScale.of(BuildContext context, BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final raw = width / _baseWidth;
    final clamped = raw.clamp(_minScale, _maxScale);
    return ChartScale._(
      scale: clamped,
      isCompact: width < AppLayoutMetrics.mobileBreakpoint,
      textScale: MediaQuery.textScalerOf(context).scale(1),
      desktopChartHeight:
          MediaQuery.sizeOf(context).width >= AppLayoutMetrics.desktopBreakpoint
          ? (MediaQuery.sizeOf(context).height * 0.38).clamp(280.0, 380.0)
          : null,
    );
  }

  /// Width (in logical pixels) at which [scale] equals 1.0.
  static const double _baseWidth = 820;

  /// Minimum / maximum scale factor.
  static const double _minScale = 0.78;
  static const double _maxScale = 1.45;

  /// Logical width used when rendering results for file export.
  static const double exportWidth = _baseWidth;

  /// Pixel ratio used when rasterizing the export chart image.
  static const double exportPixelRatio = 3.0;

  /// Fixed sizing for exported chart images (PNG, JPEG, and PDF chart section).
  ///
  /// Matches the standard desktop chart at [exportWidth] with scale 1.0 so
  /// exports look identical on every platform and viewport size.
  static ChartScale get export =>
      const ChartScale._(scale: 1.0, isCompact: false, textScale: 1.0);

  /// Desktop charts use viewport height instead of growing taller with width.
  /// Export sizing continues to use its independent, fixed geometry.
  final double? desktopChartHeight;

  final double scale;
  final bool isCompact;

  /// The user's text-magnification preference. Label boxes and axis reserves
  /// are measured in raw pixels, so they must grow alongside the text they
  /// hold or magnified axis labels get clipped.
  final double textScale;

  // Layout sizes
  /// The chart height in logical pixels, adjusted for the viewport and text
  /// scale.
  double get chartHeight =>
      (desktopChartHeight ??
          (isCompact
              ? (360 * scale).clamp(300.0, 390.0)
              : (340 * scale).clamp(280.0, 540.0))) *
      textScale;

  /// The space around the chart content in logical pixels.
  double get chartOuterPadding => isCompact
      ? (14 * scale).clamp(10.0, 18.0)
      : (18 * scale).clamp(14.0, 28.0);

  // Font sizes
  /// The base font size for tick and axis labels before system text scaling.
  double get axisLabelFontSize => isCompact
      ? (10.5 * scale).clamp(9.5, 11.5)
      : (11 * scale).clamp(10.5, 15.0);

  /// The base font size for individual factor state labels.
  double get stateLabelFontSize => isCompact
      ? (11 * scale).clamp(10.0, 12.0)
      : (12 * scale).clamp(11.0, 16.0);

  /// The base font size for the factor names below the state labels.
  double get factorLabelFontSize => isCompact
      ? (12 * scale).clamp(11.0, 13.0)
      : (13 * scale).clamp(12.0, 17.0);

  // Stroke / dot sizes
  /// The radius of a plotted measurement marker in logical pixels.
  double get dotRadius => (5.5 * scale).clamp(4.5, 8.0);

  /// The outline thickness of a plotted measurement marker.
  double get dotStroke => (2.5 * scale).clamp(2.0, 3.5);

  /// The thickness of lines connecting a factor's two means.
  double get lineWidth => (3 * scale).clamp(2.5, 4.5);

  /// The thickness of the chart's horizontal reference lines.
  double get meanLineWidth => (1.5 * scale).clamp(1.2, 2.4);

  // Axis reserves
  /// Horizontal space reserved for the vertical axis tick labels, including
  /// text scaling.
  double get leftAxisReserve =>
      (isCompact ? 42 : (52 * scale).clamp(46.0, 72.0)) * textScale;

  /// Horizontal space reserved for the vertical axis title, including text
  /// scaling.
  double get yAxisNameReserve =>
      (isCompact ? 20 : (26 * scale).clamp(22.0, 36.0)) * textScale;

  // Bottom axis is two stacked rows: state labels on top, factor names below.
  /// The space above the row of state labels.
  double get stateLabelTopPad => 6.0;

  /// The width budget for a state label after text scaling.
  double get stateLabelMaxWidth =>
      (isCompact ? 68 : (92 * scale).clamp(78.0, 130.0)) * textScale;

  /// The width budget for a factor name after text scaling.
  double get factorLabelMaxWidth =>
      (isCompact ? 34 : (128 * scale).clamp(96.0, 160.0)) * textScale;

  /// The height of the state label row, with room for angled labels in compact
  /// charts.
  double get stateLabelRowHeight => isCompact
      ? stateLabelMaxWidth + stateLabelTopPad + 4
      : stateLabelFontSize * textScale + stateLabelTopPad + 6;

  /// The vertical gap between the state labels and factor names.
  double get factorLabelGap => (10 * scale).clamp(8.0, 14.0);

  /// The height reserved for factor names below the state label row.
  double get factorLabelRowHeight => factorLabelFontSize * textScale + 6;

  /// The total height reserved for both bottom label rows and the gap between
  /// them.
  double get bottomStateLabelReserve =>
      stateLabelRowHeight + factorLabelGap + factorLabelRowHeight;

  // Legend
  /// The horizontal space used by a legend marker.
  double get legendIconWidth => (28 * scale).clamp(24.0, 38.0);

  /// The height of a legend marker in logical pixels.
  double get legendIconHeight => 14;

  /// The gap between a legend marker and its text.
  double get legendIconLabelGap => 6;

  /// The horizontal gap between legend items on one line.
  double get legendItemSpacing => isCompact ? 10 : 18;

  /// The vertical gap when legend items wrap to another line.
  double get legendRunSpacing => isCompact ? 8 : 10;

  // Conclusion row
  /// The gap between the factor marker and its conclusion text.
  double get conclusionRowFactorGap => 10;

  /// The space before the conclusion's status pill.
  double get conclusionRowPillGap => 12;

  /// The gap between labels within a factor conclusion.
  double get conclusionRowLabelGap => 2;

  /// Axis label paddings reused by the chart's axes and reference lines.
  EdgeInsets get axisNamePadding => const EdgeInsets.only(bottom: 6);

  /// Padding between the vertical axis tick labels and the plot.
  EdgeInsets get yTickPadding => const EdgeInsets.only(right: 6);

  /// Padding that positions a label above a horizontal reference line.
  EdgeInsets get topRefLabelPadding =>
      const EdgeInsets.only(right: 6, bottom: 2);

  /// Padding that positions a label below a horizontal reference line.
  EdgeInsets get bottomRefLabelPadding =>
      const EdgeInsets.only(right: 6, top: 2);
}
