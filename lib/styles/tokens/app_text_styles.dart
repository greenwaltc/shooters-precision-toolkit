// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../app_design.dart';

/// Text-style tokens layered on top of the active [ThemeData.textTheme].
///
/// These helpers exist so widgets can write
/// `style: AppTextStyles.statLabel(context)` instead of repeating
/// `textTheme.labelSmall?.copyWith(letterSpacing: 0.8, color: ...)` literals
/// in many places. Where a style is fully described by [TextTheme] alone
/// (e.g. plain `titleLarge`), widgets should read it directly off the theme.
class AppTextStyles {
  const AppTextStyles._();

  /// Section title styling for forms ("Choose your risk level", etc.).
  static TextStyle? sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;

  /// Per-factor label inside a grouped form panel.
  static TextStyle? factorLabel(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall;

  /// Uppercase + tracked label used by stat tiles and stat blocks.
  static TextStyle? statLabel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: AppDesign.weightSemiBold,
      letterSpacing: 0.8,
    );
  }

  /// Bold value styling used by stat tiles (paired with [statLabel]).
  static TextStyle? statValue(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleMedium?.copyWith(fontWeight: AppDesign.weightBold);

  /// Heading inside the header summary card.
  static TextStyle? headerSummaryTitle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleLarge?.copyWith(fontWeight: AppDesign.weightSemiBold);

  /// Header style for the form's risk-level / detection table.
  static TextStyle? formTableHeader(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelMedium?.copyWith(fontWeight: AppDesign.weightBold);

  /// Renderer text style for non-editable factor cells in [PlutoGrid].
  static TextStyle plutoFactorCell(BuildContext context) {
    return TextStyle(
      fontWeight: AppDesign.weightMedium,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// Product tagline rendered beneath the logo on the projects banner.
  static TextStyle? bannerTagline(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: AppDesign.lineHeightBody,
    );
  }

  /// Header text style for [PlutoGrid] columns.
  static const TextStyle plutoColumn = TextStyle(
    fontWeight: AppDesign.weightBold,
  );
}
