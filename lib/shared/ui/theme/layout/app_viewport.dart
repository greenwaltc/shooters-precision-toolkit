// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Text scaling and viewport spacing policies shared by app layouts.
class AppViewport {
  const AppViewport._();

  /// Cap applied to the copyright footer so OS-level large text does not make
  /// the pinned bar dominate short viewports (especially Windows).
  static const double maxFooterTextScaleFactor = 1.15;

  /// Lower bound applied to the user's text-scale preference.
  ///
  /// Allows users to shrink text slightly while preventing illegibly small
  /// content that some browser/OS settings can request.
  static const double minTextScaleFactor = 0.8;

  /// Text can grow to the platform's largest accessibility scale. Dense
  /// surfaces scroll/reflow rather than shrinking the user's preference.
  static const double maxTextScaleFactor = double.infinity;

  /// Applies a supported text scaler to [mediaQuery].
  ///
  /// The text-scale clamp keeps the app responsive to magnification while
  /// guaranteeing layouts stay usable; see [clampTextScaler].
  static MediaQueryData withSupportedTextScale(MediaQueryData mediaQuery) =>
      mediaQuery.copyWith(textScaler: clampTextScaler(mediaQuery.textScaler));

  /// Constrains [scaler] to the supported [minTextScaleFactor]..
  /// [maxTextScaleFactor] range so magnified text remains legible without
  /// breaking dense layouts.
  static TextScaler clampTextScaler(TextScaler scaler) {
    return scaler.clamp(
      minScaleFactor: minTextScaleFactor,
      maxScaleFactor: maxTextScaleFactor,
    );
  }

  /// Extra padding for the last item in a scroll view above a pinned action.
  ///
  /// Pages that pin the copyright footer as `bottomNavigationBar` already clear the system
  /// gesture/taskbar region in the footer, and re-adding that inset here only
  /// created a dead band above the pinned button.
  static EdgeInsets scrollBottomPadding(BuildContext context) {
    return const EdgeInsets.only(bottom: AppSpacing.xl);
  }

  /// Text scaler for the pinned copyright footer.
  static TextScaler footerTextScaler(BuildContext context) {
    return MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: minTextScaleFactor,
      maxScaleFactor: maxFooterTextScaleFactor,
    );
  }
}
