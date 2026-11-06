// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

/// Visual edges that can show a scroll affordance overlay.
enum ScrollCueEdge { left, right, top, bottom }

/// Styling constants and helpers for scroll-cue edge overlays.
///
/// Shared by scrollable surfaces such as the ANOMR matrix grid and the
/// project setup form.
class ScrollCueStyle {
  const ScrollCueStyle._();

  /// Width or height of the scroll affordance overlay.
  static const double extent = 24;

  /// Size and opacity of the single directional chevron.
  static const double iconSize = 16;
  static const double iconOpacity = 0.7;

  /// Gradient used to fade the scroll cue into the surface beneath it.
  static LinearGradient gradient({
    required ScrollCueEdge edge,
    required Color surface,
  }) {
    final (begin, end) = switch (edge) {
      ScrollCueEdge.left => (Alignment.centerLeft, Alignment.centerRight),
      ScrollCueEdge.right => (Alignment.centerRight, Alignment.centerLeft),
      ScrollCueEdge.top => (Alignment.topCenter, Alignment.bottomCenter),
      ScrollCueEdge.bottom => (Alignment.bottomCenter, Alignment.topCenter),
    };
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        for (final alpha in const [0.82, 0.74, 0.52, 0.27, 0.1, 0.02, 0.0])
          surface.withValues(alpha: alpha),
      ],
      stops: const [0, 0.15, 0.33, 0.52, 0.7, 0.87, 1],
    );
  }

  /// Icon that communicates the scroll direction for [edge].
  static IconData icon(ScrollCueEdge edge) => switch (edge) {
    ScrollCueEdge.left => Icons.keyboard_arrow_left_rounded,
    ScrollCueEdge.right => Icons.keyboard_arrow_right_rounded,
    ScrollCueEdge.top => Icons.keyboard_arrow_up_rounded,
    ScrollCueEdge.bottom => Icons.keyboard_arrow_down_rounded,
  };
}
