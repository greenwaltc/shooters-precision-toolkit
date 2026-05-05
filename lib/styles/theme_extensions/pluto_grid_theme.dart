import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';

/// [ThemeExtension] capturing the styling tokens used to configure
/// `PlutoGrid`. PlutoGrid has its own configuration object, so we expose
/// these tokens as a [ThemeExtension] instead of pushing them into a
/// component theme on [ThemeData].
@immutable
class PlutoGridStyleTheme extends ThemeExtension<PlutoGridStyleTheme> {
  const PlutoGridStyleTheme({
    required this.borderColor,
    required this.backgroundColor,
    required this.factorCellBackground,
    required this.borderRadius,
    required this.rowHeight,
    required this.columnHeight,
    required this.scrollbarThickness,
    required this.scrollbarRadius,
  });

  /// Standard configuration matching the rest of the app's outlined surfaces.
  const PlutoGridStyleTheme.standard()
      : borderColor = const Color(0xFFE0E0E0),
        backgroundColor = const Color(0xFFFFFFFF),
        factorCellBackground = const Color(0xFFF5F5F5),
        borderRadius = AppRadius.smRadius,
        rowHeight = 48,
        columnHeight = 52,
        scrollbarThickness = 8,
        scrollbarRadius = const Radius.circular(10);

  final Color borderColor;
  final Color backgroundColor;

  /// Background color used by the read-only factor-column cell renderer.
  final Color factorCellBackground;

  final BorderRadius borderRadius;
  final double rowHeight;
  final double columnHeight;
  final double scrollbarThickness;
  final Radius scrollbarRadius;

  @override
  PlutoGridStyleTheme copyWith({
    Color? borderColor,
    Color? backgroundColor,
    Color? factorCellBackground,
    BorderRadius? borderRadius,
    double? rowHeight,
    double? columnHeight,
    double? scrollbarThickness,
    Radius? scrollbarRadius,
  }) {
    return PlutoGridStyleTheme(
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      factorCellBackground: factorCellBackground ?? this.factorCellBackground,
      borderRadius: borderRadius ?? this.borderRadius,
      rowHeight: rowHeight ?? this.rowHeight,
      columnHeight: columnHeight ?? this.columnHeight,
      scrollbarThickness: scrollbarThickness ?? this.scrollbarThickness,
      scrollbarRadius: scrollbarRadius ?? this.scrollbarRadius,
    );
  }

  @override
  PlutoGridStyleTheme lerp(
    ThemeExtension<PlutoGridStyleTheme>? other,
    double t,
  ) {
    if (other is! PlutoGridStyleTheme) return this;
    return PlutoGridStyleTheme(
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t) ??
              backgroundColor,
      factorCellBackground:
          Color.lerp(factorCellBackground, other.factorCellBackground, t) ??
              factorCellBackground,
      borderRadius:
          BorderRadius.lerp(borderRadius, other.borderRadius, t) ??
              borderRadius,
      rowHeight: _lerp(rowHeight, other.rowHeight, t),
      columnHeight: _lerp(columnHeight, other.columnHeight, t),
      scrollbarThickness:
          _lerp(scrollbarThickness, other.scrollbarThickness, t),
      scrollbarRadius:
          Radius.lerp(scrollbarRadius, other.scrollbarRadius, t) ??
              scrollbarRadius,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
