// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../styles/app_design.dart';

/// Route transition that fades the incoming page in and hides the outgoing
/// page immediately (no horizontal slide).
///
/// Transparent scaffolds make Material's default slide-away jarring: the prior
/// page stays visible while it scoots left. This builder keeps the atmosphere
/// steady and only cross-fades the new route.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, child) {
        // Covered by a route on top — drop out of the tree immediately so
        // nothing slides away over the shared atmosphere.
        if (secondaryAnimation.value > 0) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppDesign.motionCurve,
            reverseCurve: AppDesign.motionCurve.flipped,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// [PageTransitionsTheme] that applies [AppPageTransitionsBuilder] on every
/// platform.
PageTransitionsTheme buildAppPageTransitionsTheme() {
  return PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const AppPageTransitionsBuilder(),
    },
  );
}

/// Named-route page that uses the app fade transition and motion durations.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => AppDesign.motionMedium;

  @override
  Duration get reverseTransitionDuration => AppDesign.motionFast;
}
