// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../app_design.dart';

/// Semantic heading scale for page and section titles.
///
/// Prefer these over raw [TextTheme] lookups when marking hierarchical titles
/// so weight, tracking, and role stay consistent across the app. Map roughly
/// to HTML heading levels:
///   * [h1] — page hero / primary screen title
///   * [h2] — secondary page title (e.g. app-bar route label beside the logo)
///   * [h3] — major section within a page
///   * [h4] — subsection / card title
///   * [h5] — compact group label
///   * [h6] — smallest titled grouping
class AppHeadings {
  const AppHeadings._();

  /// Largest page-level title.
  static TextStyle? h1(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge?.copyWith(
      fontWeight: AppDesign.headlineWeight,
      letterSpacing: AppDesign.headlineTracking,
      height: AppDesign.lineHeightTitle,
    );
  }

  /// Secondary page title — used for app-bar labels beside the brand mark.
  static TextStyle? h2(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: AppDesign.headlineWeight,
      letterSpacing: AppDesign.headlineTracking,
      height: AppDesign.lineHeightTitle,
    );
  }

  /// Major in-page section heading.
  static TextStyle? h3(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: AppDesign.titleLargeWeight,
      letterSpacing: AppDesign.titleLargeTracking,
      height: AppDesign.lineHeightTitle,
    );
  }

  /// Subsection / panel title.
  static TextStyle? h4(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: AppDesign.titleWeight,
      letterSpacing: AppDesign.titleTracking,
      height: AppDesign.lineHeightTitle,
    );
  }

  /// Compact group label.
  static TextStyle? h5(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: AppDesign.titleWeight,
      letterSpacing: AppDesign.titleTracking,
      height: AppDesign.lineHeightTitle,
    );
  }

  /// Smallest titled grouping.
  static TextStyle? h6(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: AppDesign.labelWeight,
      letterSpacing: AppDesign.labelTracking,
      height: AppDesign.lineHeightTitle,
    );
  }
}
