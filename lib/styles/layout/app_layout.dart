// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_viewport.dart';
import '../tokens/app_spacing.dart';

typedef AppLayoutWidgetBuilder =
    Widget Function(BuildContext context, AppLayoutMetrics layout);

/// Shared responsive layout rules for app pages and dense tool surfaces.
///
/// Widgets should ask this object for breakpoints, page padding, and max
/// content widths instead of each page inventing local `LayoutBuilder`
/// thresholds.
@immutable
class AppLayoutMetrics {
  const AppLayoutMetrics({required this.width});

  final double width;

  static const double mobileBreakpoint = 720;
  static const double desktopBreakpoint = 1024;

  bool get isMobile => width < mobileBreakpoint;
  bool get isDesktop => width >= desktopBreakpoint;

  bool get useTwoColumnForms => width >= 900;
  bool get useStackedActions => width < 560;

  double get pageGutter => isMobile ? AppSpacing.lg : AppSpacing.xxxxl;

  EdgeInsets get pagePadding => EdgeInsets.all(pageGutter);

  EdgeInsets get toolPadding => EdgeInsets.symmetric(
    horizontal: pageGutter,
    vertical: isMobile ? AppSpacing.md : AppSpacing.xl,
  );

  double get homeMaxWidth => isDesktop ? 980 : double.infinity;
  double get formMaxWidth => isDesktop ? 1080 : double.infinity;
  double get resultsMaxWidth => isDesktop ? 1180 : double.infinity;
  double get matrixHeaderMaxWidth => isDesktop ? 1180 : double.infinity;
}

class AppLayoutBuilder extends StatelessWidget {
  const AppLayoutBuilder({super.key, required this.builder});

  final AppLayoutWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        return builder(context, AppLayoutMetrics(width: width));
      },
    );
  }
}

class AppResponsiveBody extends StatelessWidget {
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
    return SafeArea(
      minimum: AppViewport.safeAreaMinimum,
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

class AppResponsiveActions extends StatelessWidget {
  const AppResponsiveActions({
    super.key,
    required this.children,
    required this.layout,
    this.desktopAlignment = MainAxisAlignment.end,
  });

  final List<Widget> children;
  final AppLayoutMetrics layout;
  final MainAxisAlignment desktopAlignment;

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

    return Row(
      mainAxisAlignment: desktopAlignment,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}
