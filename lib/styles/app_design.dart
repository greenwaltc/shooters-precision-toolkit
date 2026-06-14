// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

/// The single, central configuration hub for the app's entire visual language.
///
/// ## What this is
/// Every "knob" you can turn to change the look and feel of the app lives in
/// this file as a documented `static const`. Change a value here and it
/// propagates everywhere automatically:
///
///   * [AppTheme] (`styles/app_theme.dart`) builds the global [ThemeData]
///     — colors, typography, buttons, inputs, cards, dialogs, etc. — entirely
///     from these knobs.
///   * The semantic token classes (`AppColors`, `AppSpacing`, `AppRadius`,
///     `AppBorders`, `AppOpacity`) are thin, typed facets that simply re-expose
///     the values defined here, so widget code keeps reading
///     `AppSpacing.xl` / `AppRadius.mdRadius` while the *numbers* live in one
///     place.
///
/// ## How to use it
/// Tweak the constants in the section you care about. The sections are:
///   1. Brand & color
///   2. Spacing scale
///   3. Corner radii
///   4. Border widths
///   5. Elevation
///   6. Opacity tints
///   7. Typography
///   8. Buttons
///   9. Inputs
///  10. Cards & surfaces
///  11. List tiles
///  12. App bar
///  13. Motion
///
/// ## Rules of the road
///   * Never hardcode a raw color/number in a widget — add or reuse a knob here.
///   * Keep scales tight; adding a value should be a deliberate design call.
///   * Everything is `const` so it stays usable from other `const` token
///     definitions (Dart forbids reading instance fields in a `const`
///     expression, which is why this is a flat class of statics rather than a
///     nested config object).
class AppDesign {
  const AppDesign._();

  // ───────────────────────────── 1. Brand & color ─────────────────────────
  //
  // The whole [ColorScheme] is generated from a single [seedColor] using
  // Material 3's tonal algorithm, so changing the seed re-themes the app.

  /// Master brand color. Drives the generated [ColorScheme].
  static const Color seedColor = Colors.deepPurple;

  /// Tonal algorithm used by `ColorScheme.fromSeed`.
  ///
  /// `tonalSpot` is the Material 3 default (balanced, branded). Alternatives
  /// worth trying: `vibrant` (more saturated), `expressive`, `fidelity`
  /// (stays closest to the seed), or `neutral` (muted/greyscale).
  static const DynamicSchemeVariant schemeVariant =
      DynamicSchemeVariant.tonalSpot;

  /// Theme mode applied before the user has made a choice (or after they pick
  /// "follow system"). `ThemeMode.system` honors the OS/browser light/dark
  /// preference; switch to `light` or `dark` to force a default.
  static const ThemeMode defaultThemeMode = ThemeMode.system;

  /// Six-stop categorical palette for the per-factor chart series, legend
  /// dots, and conclusion rows. Chosen to stay distinguishable on light and
  /// dark surfaces and to avoid red (reserved for risk-bound semantics).
  static const List<Color> factorPalette = <Color>[
    Color(0xFF2E7DD1), // azure
    Color(0xFFE07B2E), // amber-orange
    Color(0xFF2EA87B), // jade green
    Color(0xFF8B4FBF), // violet
    Color(0xFFC62957), // berry
    Color(0xFF3F6E8C), // slate blue
  ];

  /// Background fill used when stitching captured chart frames into an export
  /// image (PNG/JPEG).
  static const Color exportImageBackground = Color(0xFFFFFFFF);

  /// Stroke painted around chart/legend marker dots for clean separation.
  static const Color chartDotOutline = Color(0xFFFFFFFF);

  // ───────────────────────────── 2. Spacing scale ─────────────────────────
  //
  // A compact 4-based scale. Prefer the named [AppSpacing] aliases in widget
  // code; the raw values live here so the rhythm of the whole UI can be
  // rebalanced by editing one ladder.

  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ───────────────────────────── 3. Corner radii ──────────────────────────
  //
  // Larger, more consistent radii read as more modern. Buttons, inputs, and
  // grouped panels share [radiusMd]; cards use [radiusLg]; hero surfaces and
  // dialogs use [radiusXl].

  static const double radiusSm = 8;
  static const double radiusBottomSheet = 14;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  /// Pill / stadium radius for status chips and selectable highlights.
  static const double radiusPill = 999;

  // ───────────────────────────── 4. Border widths ─────────────────────────

  /// Extra-fine separators (PDF table grid lines, etc.).
  static const double borderHairline = 0.5;

  /// Default outlined-card / list-tile border.
  static const double borderThin = 1.0;

  /// Slightly emphasized borders (text fields, grouped panels).
  static const double borderRegular = 1.5;

  /// Focus / active-state borders.
  static const double borderFocus = 2.0;

  // ───────────────────────────── 5. Elevation ─────────────────────────────
  //
  // The app is intentionally flat: separation comes from hairline borders and
  // surface tints rather than drop shadows.

  static const double elevationNone = 0;

  /// Subtle lift applied to the app bar once content scrolls beneath it.
  static const double appBarScrolledElevation = 1.0;

  /// Floating elements (dialogs, menus, snackbars, sheets).
  static const double elevationFloating = 3.0;

  // ───────────────────────────── 6. Opacity tints ─────────────────────────
  //
  // Alpha values for layered tints. Most colors should come straight from the
  // [ColorScheme]; use these only where a translucent overlay is part of the
  // design.

  /// Tint for the emphasized "summary" card on top of a container surface.
  static const double tintCard = 0.45;

  /// Factor-color tint used as a conclusion-row background fill.
  static const double tintRowFill = 0.06;

  /// Factor-color tint used as a conclusion-row border.
  static const double tintRowBorder = 0.35;

  /// Status-color tint used as a status-pill fill.
  static const double tintPillFill = 0.12;

  /// Status-color tint used as a status-pill border.
  static const double tintPillBorder = 0.40;

  /// Background tint applied to a selected list tile / radio row.
  static const double tintSelected = 0.40;

  /// Subtle horizontal grid lines on the chart.
  static const double tintChartGridLine = 0.6;

  /// Neutral reference accents (grand-mean line) derived from `onSurface`.
  static const double tintNeutralReference = 0.6;

  /// Fade applied to disabled / non-applicable controls.
  static const double tintDisabled = 0.5;

  // ───────────────────────────── 7. Typography ────────────────────────────
  //
  // The app uses the platform default type family but tightens weights,
  // tracking (letter spacing), and line height so headings feel crisp and
  // body copy stays readable. [AppTheme] applies these per text role.

  /// Optional override font family. `null` keeps the platform default
  /// (Roboto on Android/web, San Francisco on Apple). To ship a custom font,
  /// declare it under `flutter > fonts` in `pubspec.yaml` and set its family
  /// name here.
  static const String? fontFamily = null;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  /// Tracking (letter spacing) ladder, in logical pixels.
  static const double trackingTight = -0.5;
  static const double trackingSnug = -0.2;
  static const double trackingNormal = 0.0;
  static const double trackingWide = 0.3;

  /// Line-height multipliers.
  static const double lineHeightTitle = 1.2;
  static const double lineHeightBody = 1.45;

  // Per-role weights/tracking applied to the base Material text theme.
  static const FontWeight displayWeight = weightBold;
  static const double displayTracking = trackingTight;

  static const FontWeight headlineWeight = weightSemiBold;
  static const double headlineTracking = trackingSnug;

  static const FontWeight titleLargeWeight = weightBold;
  static const double titleLargeTracking = trackingSnug;

  static const FontWeight titleWeight = weightSemiBold;
  static const double titleTracking = trackingNormal;

  static const FontWeight labelWeight = weightSemiBold;
  static const double labelTracking = trackingWide;

  // ───────────────────────────── 8. Buttons ───────────────────────────────
  //
  // All button variants (filled, elevated, outlined, text) share one shape,
  // height, padding, and label style so primary/secondary actions read as one
  // family. Primary calls-to-action should use [FilledButton].

  static const double buttonMinHeight = 50;
  static const double buttonRadius = radiusMd;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: space24,
    vertical: space12,
  );

  // ───────────────────────────── 9. Inputs ────────────────────────────────

  static const double inputRadius = radiusMd;
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space16,
  );

  // ──────────────────────────── 10. Cards & surfaces ──────────────────────

  static const double cardRadius = radiusLg;
  static const double cardBorderWidth = borderThin;
  static const double dialogRadius = radiusXl;
  static const double bottomSheetRadius = radiusBottomSheet;

  // ──────────────────────────── 11. List tiles ────────────────────────────

  static const double listTileRadius = radiusMd;
  static const EdgeInsets listTileContentPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space8,
  );

  /// Size of the tinted leading icon container on list/hero surfaces.
  static const double leadingIconBadgeSize = 40;

  // ──────────────────────────── 12. App bar ───────────────────────────────

  /// Whether app-bar titles are centered. Left-aligned reads more like a
  /// modern productivity app.
  static const bool appBarCenterTitle = false;

  // ──────────────────────────── 13. Motion ────────────────────────────────

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionMedium = Duration(milliseconds: 250);
  static const Duration motionSlow = Duration(milliseconds: 400);

  /// Default easing for transitions and reveals.
  static const Curve motionCurve = Curves.easeInOutCubic;
}
