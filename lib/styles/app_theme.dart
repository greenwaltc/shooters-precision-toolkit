// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../navigation/app_page_transitions.dart';
import 'app_design.dart';
import 'theme_extensions/anomr_chart_theme.dart';
import 'theme_extensions/factor_palette_theme.dart';
import 'theme_extensions/pluto_grid_theme.dart';
import 'tokens/app_colors.dart';

/// Builds the [ThemeData] used by the Bramwell's Precision Test Kit.
///
/// This file contains **no design constants of its own** — every color,
/// radius, weight, size, and duration is read from [AppDesign], the single
/// configuration hub. To restyle the app, edit [AppDesign]; this file only
/// wires those knobs into Material's component themes so consumer widgets stay
/// free of styling code.
class AppTheme {
  const AppTheme._();

  /// Default light theme.
  static ThemeData light() => _themeForBrightness(Brightness.light);

  /// Dark counterpart to [light]. Generated from the same [AppDesign] knobs
  /// (seed color, tonal variant, typography, shapes), so light and dark stay
  /// visually consistent.
  static ThemeData dark() => _themeForBrightness(Brightness.dark);

  static ThemeData _themeForBrightness(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      dynamicSchemeVariant: AppDesign.schemeVariant,
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: AppDesign.fontFamily,
    );

    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      // Transparent so [AppAtmosphere] (mounted in MaterialApp.builder) shows
      // through every scaffold, including behind app bars.
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: buildAppPageTransitionsTheme(),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: _cardTheme(colorScheme),
      dialogTheme: _dialogTheme(colorScheme, textTheme),
      bottomSheetTheme: _bottomSheetTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      snackBarTheme: _snackBarTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme, textTheme),
      dividerTheme: _dividerTheme(colorScheme),
      listTileTheme: _listTileTheme(colorScheme),
      filledButtonTheme: FilledButtonThemeData(style: _primaryButtonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle().copyWith(
          elevation: const WidgetStatePropertyAll(AppDesign.elevationNone),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(colorScheme),
      ),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle()),
      segmentedButtonTheme: _segmentedButtonTheme(),
      radioTheme: _toggleableTheme(colorScheme),
      checkboxTheme: _checkboxTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
      extensions: _extensionsFor(colorScheme),
    );
  }

  static List<ThemeExtension<dynamic>> _extensionsFor(ColorScheme colorScheme) {
    return [
      const FactorPaletteTheme.standard(),
      const AnomrChartTheme.standard(),
      PlutoGridStyleTheme.fromColorScheme(colorScheme),
    ];
  }

  // ───────────────────────────── Typography ───────────────────────────────

  /// Applies [AppDesign]'s weight / tracking / line-height knobs to the base
  /// Material text theme so headings feel crisp and body copy reads cleanly.
  static TextTheme _textTheme(TextTheme base) {
    TextStyle? display(TextStyle? s) => s?.copyWith(
      fontWeight: AppDesign.displayWeight,
      letterSpacing: AppDesign.displayTracking,
      height: AppDesign.lineHeightTitle,
    );
    TextStyle? headline(TextStyle? s) => s?.copyWith(
      fontWeight: AppDesign.headlineWeight,
      letterSpacing: AppDesign.headlineTracking,
      height: AppDesign.lineHeightTitle,
    );
    TextStyle? title(TextStyle? s, FontWeight weight, double tracking) =>
        s?.copyWith(
          fontWeight: weight,
          letterSpacing: tracking,
          height: AppDesign.lineHeightTitle,
        );
    TextStyle? body(TextStyle? s) =>
        s?.copyWith(height: AppDesign.lineHeightBody);
    TextStyle? label(TextStyle? s) => s?.copyWith(
      fontWeight: AppDesign.labelWeight,
      letterSpacing: AppDesign.labelTracking,
    );

    return base.copyWith(
      displayLarge: display(base.displayLarge),
      displayMedium: display(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: headline(base.headlineLarge),
      headlineMedium: headline(base.headlineMedium),
      headlineSmall: headline(base.headlineSmall),
      titleLarge: title(
        base.titleLarge,
        AppDesign.titleLargeWeight,
        AppDesign.titleLargeTracking,
      ),
      titleMedium: title(
        base.titleMedium,
        AppDesign.titleWeight,
        AppDesign.titleTracking,
      ),
      titleSmall: title(
        base.titleSmall,
        AppDesign.titleWeight,
        AppDesign.titleTracking,
      ),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: label(base.labelLarge),
      labelMedium: label(base.labelMedium),
      labelSmall: label(base.labelSmall),
    );
  }

  // ───────────────────────────── Buttons ──────────────────────────────────

  /// Shared geometry for every button variant so primary, secondary, and
  /// tertiary actions read as one family.
  static ButtonStyle _baseButtonStyle() {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(0, AppDesign.buttonMinHeight),
      ),
      padding: const WidgetStatePropertyAll(AppDesign.buttonPadding),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonRadius),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontWeight: AppDesign.labelWeight,
          letterSpacing: AppDesign.labelTracking,
        ),
      ),
    );
  }

  static ButtonStyle _primaryButtonStyle() => _baseButtonStyle();

  static ButtonStyle _outlinedButtonStyle(ColorScheme scheme) {
    return _baseButtonStyle().copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.disabled)
            ? scheme.outlineVariant
            : scheme.outline;
        return BorderSide(color: color, width: AppDesign.borderThin);
      }),
    );
  }

  static ButtonStyle _textButtonStyle() {
    return _baseButtonStyle().copyWith(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppDesign.space16,
          vertical: AppDesign.space12,
        ),
      ),
    );
  }

  static SegmentedButtonThemeData _segmentedButtonTheme() {
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.buttonRadius),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Surfaces ─────────────────────────────────

  static CardThemeData _cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: AppDesign.elevationNone,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: AppDesign.cardBorderWidth,
        ),
      ),
    );
  }

  static DialogThemeData _dialogTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return DialogThemeData(
      elevation: AppDesign.elevationFloating,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.dialogRadius),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppDesign.elevationFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.bottomSheetRadius),
        ),
      ),
    );
  }

  // ───────────────────────────── Inputs ───────────────────────────────────

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: AppDesign.inputContentPadding,
      border: _inputBorder(colorScheme.outline, AppDesign.borderRegular),
      enabledBorder: _inputBorder(colorScheme.outline, AppDesign.borderThin),
      focusedBorder: _inputBorder(colorScheme.primary, AppDesign.borderFocus),
      errorBorder: _inputBorder(colorScheme.error, AppDesign.borderThin),
      focusedErrorBorder: _inputBorder(
        colorScheme.error,
        AppDesign.borderFocus,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesign.inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ───────────────────────────── Toggles ──────────────────────────────────

  static RadioThemeData _toggleableTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.onSurfaceVariant;
      }),
    );
  }

  static CheckboxThemeData _checkboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
      side: BorderSide(
        color: colorScheme.onSurfaceVariant,
        width: AppDesign.borderRegular,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusSm / 2),
      ),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      side: BorderSide(color: colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
      ),
    );
  }

  // ───────────────────────────── Chrome ───────────────────────────────────

  static SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: AppDesign.elevationFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      ),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return AppBarTheme(
      elevation: AppDesign.elevationNone,
      scrolledUnderElevation: AppDesign.elevationNone,
      centerTitle: AppDesign.appBarCenterTitle,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    );
  }

  static DividerThemeData _dividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      space: 1,
      thickness: 1,
    );
  }

  static ListTileThemeData _listTileTheme(ColorScheme colorScheme) {
    return ListTileThemeData(
      contentPadding: AppDesign.listTileContentPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.listTileRadius),
      ),
      selectedColor: colorScheme.onSecondaryContainer,
      selectedTileColor: colorScheme.secondaryContainer.withValues(
        alpha: AppDesign.tintSelected,
      ),
      iconColor: colorScheme.onSurfaceVariant,
    );
  }
}
