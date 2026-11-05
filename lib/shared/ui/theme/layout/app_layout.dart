// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Builds a widget using the space and breakpoint information available to it.
typedef AppLayoutWidgetBuilder =
    Widget Function(BuildContext context, AppLayoutMetrics layout);

/// Shared responsive layout rules for app pages and dense tool surfaces.
///
/// Widgets should ask this object for breakpoints, page padding, and max
/// content widths instead of each page inventing local `LayoutBuilder`
/// thresholds.
@immutable
class AppLayoutMetrics {
  /// Describes a layout with [width] and [height] in logical pixels.
  const AppLayoutMetrics({required this.width, required this.height});

  /// Content/viewport width used for breakpoints.
  final double width;

  /// Full viewport height (from [MediaQuery]), used for orientation chrome.
  final double height;

  static const double mobileBreakpoint = 720;
  static const double desktopBreakpoint = 1024;

  /// Reads the viewport dimensions available from [context].
  factory AppLayoutMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppLayoutMetrics(width: size.width, height: size.height);
  }

  /// Whether the available width calls for the compact layout.
  bool get isMobile =>
      width < mobileBreakpoint || (width < desktopBreakpoint && height < 500);

  /// Whether the available width reaches the desktop breakpoint.
  bool get isDesktop => width >= desktopBreakpoint;

  /// Mobile width with a landscape viewport — prioritize body height.
  bool get isMobileLandscape => isMobile && height < width;

  /// Shrink app bars, banners, and vertical page padding.
  bool get preferCompactChrome => isMobileLandscape;

  /// Whether the form can place related fields in two columns.
  bool get useTwoColumnForms => width >= 900;

  /// Whether action buttons should be arranged vertically.
  bool get useStackedActions => width < 560;

  /// The horizontal page margin in logical pixels for this layout.
  double get pageGutter =>
      isMobile ? AppSpacing.lg : (isDesktop ? 24 : AppSpacing.xxxxl);

  /// Vertical gutter; tighter on mobile landscape to reclaim body height.
  double get pageGutterVertical =>
      isMobile ? AppSpacing.md : (isDesktop ? 12 : pageGutter);

  /// The page margins for this layout as padding.
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
    horizontal: pageGutter,
    vertical: pageGutterVertical,
  );

  /// The maximum content width for the project list.
  double get homeMaxWidth => isDesktop ? 1200 : double.infinity;

  /// The maximum content width for the test design form.
  double get formMaxWidth => isDesktop ? 1280 : double.infinity;

  /// The maximum content width for results.
  double get resultsMaxWidth => isDesktop ? 1180 : double.infinity;

  /// The maximum content width for the matrix header.
  double get matrixHeaderMaxWidth => isDesktop ? 1440 : double.infinity;

  /// Help instructions sheet uses full width on mobile; 80% of the viewport
  /// on tablet and desktop so long-form text stays readable without feeling narrow.
  double get helpInstructionsMaxWidth =>
      isMobile ? double.infinity : width * 0.8;
}

/// A builder that supplies responsive metrics for the available layout space.
class AppLayoutBuilder extends StatelessWidget {
  /// Creates a layout-aware widget using [builder].
  const AppLayoutBuilder({super.key, required this.builder});

  final AppLayoutWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : mediaSize.width;
        return builder(
          context,
          AppLayoutMetrics(width: width, height: mediaSize.height),
        );
      },
    );
  }
}

/// A centered content area with viewport padding and a responsive width limit.
class AppResponsiveBody extends StatelessWidget {
  /// Creates a content area that derives its width from [maxWidth] for the
  /// current layout.
  const AppResponsiveBody({
    super.key,
    required this.builder,
    required this.maxWidth,
    this.padding,
  });

  final AppLayoutWidgetBuilder builder;
  final double Function(AppLayoutMetrics layout) maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    // Bottom inset is owned by [AppCopyrightFooter] (bottomNavigationBar) so
    // page actions are not separated from the footer by a second SafeArea pad.
    return SafeArea(
      bottom: false,
      child: AppLayoutBuilder(
        builder: (context, layout) {
          return Padding(
            padding: padding ?? layout.pagePadding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final widthLimit = maxWidth(layout);
                final contentWidth = widthLimit.isFinite
                    ? math.min(widthLimit, constraints.maxWidth)
                    : constraints.maxWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    height: constraints.hasBoundedHeight
                        ? constraints.maxHeight
                        : null,
                    child: builder(context, layout),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A group of controls that can stack or wrap according to available width.
class AppResponsiveActions extends StatelessWidget {
  /// Arranges [children] for [layout] and uses [desktopAlignment] when they
  /// wrap horizontally.
  const AppResponsiveActions({
    super.key,
    required this.children,
    required this.layout,
    this.desktopAlignment = WrapAlignment.end,
  });

  final List<Widget> children;
  final AppLayoutMetrics layout;
  final WrapAlignment desktopAlignment;

  @override
  Widget build(BuildContext context) {
    if (layout.useStackedActions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    }

    // Wrap rather than Row so wide button labels flow onto another line under
    // heavy text magnification instead of overflowing the viewport.
    return Wrap(
      alignment: desktopAlignment,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: children,
    );
  }
}
