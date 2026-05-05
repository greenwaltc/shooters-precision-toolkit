import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_opacity.dart';

/// [ThemeExtension] for chart-specific styling that doesn't fit cleanly into
/// [ColorScheme] / [TextTheme]: dot stroke colors, grid line tinting, dash
/// patterns, etc.
///
/// Pure visual configuration. Per-build *sizes* live in `ChartScale`
/// (responsive) and structural geometry lives in `ChartLayout`.
@immutable
class AnomrChartTheme extends ThemeExtension<AnomrChartTheme> {
  const AnomrChartTheme({
    required this.dotOutlineColor,
    required this.gridLineOpacity,
    required this.referenceLineOpacity,
    required this.gridLineDashArray,
    required this.boundLineDashArray,
  });

  /// Sensible defaults for the standard light theme.
  const AnomrChartTheme.standard()
      : dotOutlineColor = AppColors.chartDotOutline,
        gridLineOpacity = AppOpacity.chartGridLine,
        referenceLineOpacity = AppOpacity.neutralReference,
        gridLineDashArray = const <int>[2, 4],
        boundLineDashArray = const <int>[6, 4];

  /// Stroke color painted around chart marker dots.
  final Color dotOutlineColor;

  /// Alpha applied to `outlineVariant` when drawing horizontal grid lines.
  final double gridLineOpacity;

  /// Alpha applied to `onSurface` when drawing the grand-mean reference
  /// line and other neutral chart accents.
  final double referenceLineOpacity;

  /// Dash pattern for horizontal grid lines.
  final List<int> gridLineDashArray;

  /// Dash pattern for the upper / lower bound risk lines.
  final List<int> boundLineDashArray;

  @override
  AnomrChartTheme copyWith({
    Color? dotOutlineColor,
    double? gridLineOpacity,
    double? referenceLineOpacity,
    List<int>? gridLineDashArray,
    List<int>? boundLineDashArray,
  }) {
    return AnomrChartTheme(
      dotOutlineColor: dotOutlineColor ?? this.dotOutlineColor,
      gridLineOpacity: gridLineOpacity ?? this.gridLineOpacity,
      referenceLineOpacity: referenceLineOpacity ?? this.referenceLineOpacity,
      gridLineDashArray: gridLineDashArray ?? this.gridLineDashArray,
      boundLineDashArray: boundLineDashArray ?? this.boundLineDashArray,
    );
  }

  @override
  AnomrChartTheme lerp(ThemeExtension<AnomrChartTheme>? other, double t) {
    if (other is! AnomrChartTheme) return this;
    return AnomrChartTheme(
      dotOutlineColor:
          Color.lerp(dotOutlineColor, other.dotOutlineColor, t) ??
              dotOutlineColor,
      gridLineOpacity:
          _lerpDouble(gridLineOpacity, other.gridLineOpacity, t),
      referenceLineOpacity:
          _lerpDouble(referenceLineOpacity, other.referenceLineOpacity, t),
      gridLineDashArray: t < 0.5 ? gridLineDashArray : other.gridLineDashArray,
      boundLineDashArray:
          t < 0.5 ? boundLineDashArray : other.boundLineDashArray,
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
