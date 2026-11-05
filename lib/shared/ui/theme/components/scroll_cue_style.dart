// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Visual edges that can show a scroll affordance overlay.
enum ScrollCueEdge { left, right, top, bottom }

/// Styling constants and helpers for scroll-cue edge overlays.
///
/// Shared by scrollable surfaces such as the ANOMR matrix grid and the
/// project setup form.
class ScrollCueStyle {
  const ScrollCueStyle._();

  /// Width or height of the scroll affordance overlay.
  static const double extent = 52;

  /// Gradient used to fade the scroll cue into the surface beneath it.
  static LinearGradient gradient({
    required ScrollCueEdge edge,
    required Color surface,
  }) {
    final colors = _scrollCueColors(surface);
    final transparent = surface.withValues(alpha: 0);

    switch (edge) {
      case ScrollCueEdge.left:
        return _cueGradient(Alignment.centerLeft, Alignment.centerRight, [
          ...colors,
          transparent,
        ]);
      case ScrollCueEdge.right:
        return _cueGradient(Alignment.centerRight, Alignment.centerLeft, [
          ...colors,
          transparent,
        ]);
      case ScrollCueEdge.top:
        return _cueGradient(Alignment.topCenter, Alignment.bottomCenter, [
          ...colors,
          transparent,
        ]);
      case ScrollCueEdge.bottom:
        return _cueGradient(Alignment.bottomCenter, Alignment.topCenter, [
          ...colors,
          transparent,
        ]);
    }
  }

  /// Icon that communicates the scroll direction for [edge].
  static IconData icon(ScrollCueEdge edge) {
    switch (edge) {
      case ScrollCueEdge.left:
        return Icons.keyboard_double_arrow_left_rounded;
      case ScrollCueEdge.right:
        return Icons.keyboard_double_arrow_right_rounded;
      case ScrollCueEdge.top:
        return Icons.keyboard_double_arrow_up_rounded;
      case ScrollCueEdge.bottom:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  /// Alignment used by the cue icon for [edge].
  static Alignment iconAlignment(ScrollCueEdge edge) {
    switch (edge) {
      case ScrollCueEdge.left:
        return Alignment.centerLeft;
      case ScrollCueEdge.right:
        return Alignment.centerRight;
      case ScrollCueEdge.top:
        return Alignment.topCenter;
      case ScrollCueEdge.bottom:
        return Alignment.bottomCenter;
    }
  }

  /// Padding used by the cue icon for [edge].
  static EdgeInsets iconPadding(ScrollCueEdge edge) {
    switch (edge) {
      case ScrollCueEdge.left:
        return const EdgeInsets.only(left: AppSpacing.sm);
      case ScrollCueEdge.right:
        return const EdgeInsets.only(right: AppSpacing.sm);
      case ScrollCueEdge.top:
        return const EdgeInsets.only(top: AppSpacing.sm);
      case ScrollCueEdge.bottom:
        return const EdgeInsets.only(bottom: AppSpacing.sm);
    }
  }

  static LinearGradient _cueGradient(
    Alignment begin,
    Alignment end,
    List<Color> colors,
  ) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: const [0, 0.45, 1],
    );
  }

  static List<Color> _scrollCueColors(Color surface) {
    return [surface.withValues(alpha: 0.96), surface.withValues(alpha: 0.72)];
  }
}
