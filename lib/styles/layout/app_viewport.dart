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

  /// Lower bound applied to the user's text-scale preference.
  ///
  /// Allows users to shrink text slightly while preventing illegibly small
  /// content that some browser/OS settings can request.
  static const double minTextScaleFactor = 0.8;

  /// Upper bound applied to the user's text-scale preference.
  ///
  /// Honors browser/OS magnification (accessibility "larger text" settings and
  /// browser font-size zoom map to [MediaQueryData.textScaler]) while capping
  /// the value so dense surfaces (forms, the data matrix, result cards) reflow
  /// and scroll instead of clipping at extreme magnifications. Page-level
  /// zoom (Ctrl/Cmd +/-) is unaffected by this cap because the browser
  /// communicates it through the device pixel ratio, which the responsive
  /// breakpoints already react to.
  static const double maxTextScaleFactor = 1.6;

  /// Whether this build should add artificial bottom clearance in the browser.
  static bool get needsWebBottomClearance =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Applies web-safe bottom insets and a clamped text scaler to [mediaQuery].
  ///
  /// The text-scale clamp keeps the app responsive to magnification while
  /// guaranteeing layouts stay usable; see [clampTextScaler].
  static MediaQueryData applyWebSafeArea(MediaQueryData mediaQuery) {
    final scaled = mediaQuery.copyWith(
      textScaler: clampTextScaler(mediaQuery.textScaler),
    );

    if (!needsWebBottomClearance) return scaled;

    final reportedBottom = math.max(
      scaled.padding.bottom,
      scaled.viewPadding.bottom,
    );
    final bottom = math.max(reportedBottom, webMinimumBottomInset);

    return scaled.copyWith(
      padding: scaled.padding.copyWith(bottom: bottom),
      viewPadding: scaled.viewPadding.copyWith(bottom: bottom),
    );
  }

  /// Constrains [scaler] to the supported [minTextScaleFactor]..
  /// [maxTextScaleFactor] range so magnified text remains legible without
  /// breaking dense layouts.
  static TextScaler clampTextScaler(TextScaler scaler) {
    return scaler.clamp(
      minScaleFactor: minTextScaleFactor,
      maxScaleFactor: maxTextScaleFactor,
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
