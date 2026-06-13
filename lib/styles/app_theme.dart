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

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      cardTheme: _cardTheme(colorScheme),
      dialogTheme: _dialogTheme(),
      bottomSheetTheme: _bottomSheetTheme(),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      snackBarTheme: _snackBarTheme(colorScheme),
      drawerTheme: _drawerTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      dividerTheme: _dividerTheme(colorScheme),
      visualDensity: VisualDensity.standard,
      extensions: _extensions,
    );
  }

  static CardThemeData _cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }

  static DialogThemeData _dialogTheme() {
    return const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme() {
    return const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheetRadius),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: const OutlineInputBorder(borderRadius: AppRadius.mdRadius),
      enabledBorder: _inputBorder(colorScheme.outline, AppBorders.regular),
      focusedBorder: _inputBorder(colorScheme.primary, AppBorders.focus),
      errorBorder: _inputBorder(colorScheme.error, AppBorders.regular),
      focusedErrorBorder: _inputBorder(colorScheme.error, AppBorders.focus),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
    );
  }

  static DrawerThemeData _drawerTheme(ColorScheme colorScheme) {
    return DrawerThemeData(backgroundColor: colorScheme.surface);
  }

  static AppBarTheme _appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    );
  }

  static DividerThemeData _dividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      space: 1,
      thickness: 1,
    );
  }

  static const List<ThemeExtension<dynamic>> _extensions = [
    FactorPaletteTheme.standard(),
    AnomrChartTheme.standard(),
    PlutoGridStyleTheme.standard(),
  ];
}
