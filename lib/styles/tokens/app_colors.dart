// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../app_design.dart';

/// Foundational color tokens — a typed facet over [AppDesign].
///
/// Color *values* live in [AppDesign] (the central configuration hub); this
/// class simply re-exposes them with semantic names. Widgets should never
/// reference raw `Color(0x..)` literals; they should pull from these tokens or
/// the app's [ColorScheme] / [ThemeData] surface.
class AppColors {
  const AppColors._();

  /// Material seed color for [ColorScheme.fromSeed].
  static const Color seed = AppDesign.seedColor;

  /// Six-stop palette used to color the per-factor line segments and their
  /// matching legend / conclusion indicators.
  static const List<Color> factorPalette = AppDesign.factorPalette;

  /// Returns a stable factor color, wrapping if the palette is exhausted.
  static Color factorColor(int index) =>
      factorPalette[index % factorPalette.length];

  /// Background fill used when stitching captured chart frames into a single
  /// PNG/JPEG export image.
  static const Color exportImageBackground = AppDesign.exportImageBackground;

  /// Stroke painted around chart marker dots (and legend dots) to give them
  /// a clean separation from the underlying line.
  static const Color chartDotOutline = AppDesign.chartDotOutline;
}
