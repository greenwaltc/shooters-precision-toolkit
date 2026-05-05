import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// [ThemeExtension] exposing the per-factor color palette used by the ANOMR
/// chart, legend, and conclusion rows.
///
/// Exposed via the theme so that any widget can read the palette through
/// `Theme.of(context).extension<FactorPaletteTheme>()` and so that the
/// palette can be swapped for different themes / brands without touching
/// chart code.
@immutable
class FactorPaletteTheme extends ThemeExtension<FactorPaletteTheme> {
  const FactorPaletteTheme({required this.colors});

  /// Default palette wired up in the standard light theme.
  const FactorPaletteTheme.standard()
      : colors = AppColors.factorPalette;

  /// Ordered list of factor colors. Indexing wraps via [colorFor].
  final List<Color> colors;

  /// Returns a stable factor color, wrapping if [index] exceeds [colors].
  Color colorFor(int index) => colors[index % colors.length];

  @override
  FactorPaletteTheme copyWith({List<Color>? colors}) {
    return FactorPaletteTheme(colors: colors ?? this.colors);
  }

  @override
  FactorPaletteTheme lerp(ThemeExtension<FactorPaletteTheme>? other, double t) {
    if (other is! FactorPaletteTheme) return this;
    if (identical(this, other)) return this;
    final length = colors.length < other.colors.length
        ? colors.length
        : other.colors.length;
    return FactorPaletteTheme(
      colors: List<Color>.generate(
        length,
        (i) => Color.lerp(colors[i], other.colors[i], t) ?? colors[i],
      ),
    );
  }
}
