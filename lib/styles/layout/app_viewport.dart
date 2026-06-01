// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Viewport and safe-area helpers for browser builds.
///
/// Windows desktop browsers often report zero bottom insets even when the
/// taskbar overlaps the page. Inflating [MediaQuery] padding at the app root
/// keeps scaffold bodies, scroll views, and floating actions clear of that
/// region. macOS and other platforms rely on the browser-reported insets only.
class AppViewport {
  const AppViewport._();

  /// Minimum bottom clearance applied on Windows web when the platform reports none.
  static const double webMinimumBottomInset = 48;

  /// Whether this build should add artificial bottom clearance in the browser.
  static bool get needsWebBottomClearance =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Applies web-safe bottom insets to [mediaQuery].
  static MediaQueryData applyWebSafeArea(MediaQueryData mediaQuery) {
    if (!needsWebBottomClearance) return mediaQuery;

    final reportedBottom = math.max(
      mediaQuery.padding.bottom,
      mediaQuery.viewPadding.bottom,
    );
    final bottom = math.max(reportedBottom, webMinimumBottomInset);

    return mediaQuery.copyWith(
      padding: mediaQuery.padding.copyWith(bottom: bottom),
      viewPadding: mediaQuery.viewPadding.copyWith(bottom: bottom),
    );
  }

  /// Bottom inset after [applyWebSafeArea] has been applied.
  static double bottomInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
  }

  /// Extra padding for the last item in a scroll view.
  static EdgeInsets scrollBottomPadding(BuildContext context) {
    return EdgeInsets.only(bottom: AppSpacing.xxxl + bottomInset(context));
  }

  /// Minimum [SafeArea] insets for page bodies on Windows web.
  static EdgeInsets get safeAreaMinimum => needsWebBottomClearance
      ? const EdgeInsets.only(bottom: webMinimumBottomInset)
      : EdgeInsets.zero;
}
