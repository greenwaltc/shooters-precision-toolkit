// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import 'theme_extensions/anomr_chart_theme.dart';
import 'theme_extensions/factor_palette_theme.dart';
import 'theme_extensions/pluto_grid_theme.dart';
import 'tokens/app_borders.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_radius.dart';

/// Builds the [ThemeData] used by the Shooter's Precision Test Kit.
///
/// All app-wide styling lives here:
///   * [ColorScheme] is generated from [AppColors.seed].
///   * Per-component themes (cards, dialogs, inputs, etc.) wire token
///     values into widgets so consumer widgets stay free of styling code.
///   * [ThemeExtension]s expose chart, factor palette, and Pluto grid
///     tokens that don't fit cleanly into the standard component themes.
class AppTheme {
  const AppTheme._();

  /// Default light theme.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    return _build(colorScheme);
  }

  /// Optional dark theme. Currently unused by `MaterialApp` but provided so
  /// switching is a single one-liner away.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    return base.copyWith(
      // -- Cards ---------------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smRadius,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      // -- Dialogs -------------------------------------------------------
      dialogTheme: DialogThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.xlRadius,
        ),
      ),

      // -- Bottom sheet --------------------------------------------------
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.bottomSheetRadius,
        ),
      ),

      // -- Inputs --------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: AppBorders.regular,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppBorders.focus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppBorders.regular,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppBorders.focus,
          ),
        ),
      ),

      // -- Snackbar ------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),

      // -- Drawer --------------------------------------------------------
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
      ),

      // -- App bar -------------------------------------------------------
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // -- Divider -------------------------------------------------------
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // -- Page padding helper -------------------------------------------
      // Page-level padding is provided as a token (`AppSpacing.page`) so it
      // can be applied per-route without forcing it on every Scaffold.
      visualDensity: VisualDensity.standard,

      // -- Theme extensions ----------------------------------------------
      extensions: const <ThemeExtension<dynamic>>[
        FactorPaletteTheme.standard(),
        AnomrChartTheme.standard(),
        PlutoGridStyleTheme.standard(),
      ],
    );
  }
}
