// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

/// Foundational color tokens for the Shooter's Precision Test Kit.
///
/// Color *values* live here and nowhere else. Widgets should never reference
/// raw `Color(0x..)` literals; they should pull from these tokens or the
/// app's [ColorScheme] / [ThemeData] surface.
///
/// Colors are split into three groups:
///   * [seed] — the base seed used by [ColorScheme.fromSeed].
///   * [factorPalette] — the per-factor series colors used by the ANOMR
///     chart, legend, and per-factor conclusion rows.
///   * Static aliases for one-off colors used by export utilities.
class AppColors {
  const AppColors._();

  /// Material seed color for [ColorScheme.fromSeed].
  static const Color seed = Colors.deepPurple;

  /// Six-stop palette used to color the per-factor line segments and their
  /// matching legend / conclusion indicators.
  ///
  /// Picked to be distinguishable on both light and dark surfaces and to
  /// avoid red, which is reserved for the risk-bound semantic color.
  static const List<Color> factorPalette = <Color>[
    Color(0xFF2E7DD1), // azure
    Color(0xFFE07B2E), // amber-orange
    Color(0xFF2EA87B), // jade green
    Color(0xFF8B4FBF), // violet
    Color(0xFFC62957), // berry
    Color(0xFF3F6E8C), // slate blue
  ];

  /// Returns a stable factor color, wrapping if the palette is exhausted.
  static Color factorColor(int index) =>
      factorPalette[index % factorPalette.length];

  /// Background fill used when stitching captured chart frames into a single
  /// PNG/JPEG export image.
  static const Color exportImageBackground = Color(0xFFFFFFFF);

  /// Stroke painted around chart marker dots (and legend dots) to give them
  /// a clean separation from the underlying line.
  static const Color chartDotOutline = Color(0xFFFFFFFF);
}
