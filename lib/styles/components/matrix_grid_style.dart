// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Visual edges that can show a matrix scroll cue.
enum MatrixScrollCueEdge { left, right, top, bottom }

/// Styling constants and helpers for the ANOMR matrix grid.
class MatrixGridStyle {
  const MatrixGridStyle._();

  /// Minimum width for read-only index columns before autofit runs.
  static const double indexColumnMinWidth = 52;

  /// Default factor column width.
  static const double factorColumnWidth = 120;

  /// Default range column width.
  static const double rangeColumnWidth = 150;

  /// Matches [PlutoGridSettings.rowBorderWidth] without importing Pluto here.
  static const double rowBorderWidth = 1;

  /// Width or height of the scroll affordance overlay.
  static const double scrollCueExtent = 52;

  /// Gradient used to fade the scroll cue into the grid surface.
  static LinearGradient scrollCueGradient({
    required MatrixScrollCueEdge edge,
    required Color surface,
  }) {
    final colors = _scrollCueColors(surface);
    final transparent = surface.withValues(alpha: 0);

    switch (edge) {
      case MatrixScrollCueEdge.left:
        return _cueGradient(Alignment.centerLeft, Alignment.centerRight, [
          ...colors,
          transparent,
        ]);
      case MatrixScrollCueEdge.right:
        return _cueGradient(Alignment.centerRight, Alignment.centerLeft, [
          ...colors,
          transparent,
        ]);
      case MatrixScrollCueEdge.top:
        return _cueGradient(Alignment.topCenter, Alignment.bottomCenter, [
          ...colors,
          transparent,
        ]);
      case MatrixScrollCueEdge.bottom:
        return _cueGradient(Alignment.bottomCenter, Alignment.topCenter, [
          ...colors,
          transparent,
        ]);
    }
  }

  /// Icon that communicates the scroll direction for [edge].
  static IconData scrollCueIcon(MatrixScrollCueEdge edge) {
    switch (edge) {
      case MatrixScrollCueEdge.left:
        return Icons.keyboard_double_arrow_left_rounded;
      case MatrixScrollCueEdge.right:
        return Icons.keyboard_double_arrow_right_rounded;
      case MatrixScrollCueEdge.top:
        return Icons.keyboard_double_arrow_up_rounded;
      case MatrixScrollCueEdge.bottom:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  /// Alignment used by the cue icon for [edge].
  static Alignment scrollCueIconAlignment(MatrixScrollCueEdge edge) {
    switch (edge) {
      case MatrixScrollCueEdge.left:
        return Alignment.centerLeft;
      case MatrixScrollCueEdge.right:
        return Alignment.centerRight;
      case MatrixScrollCueEdge.top:
        return Alignment.topCenter;
      case MatrixScrollCueEdge.bottom:
        return Alignment.bottomCenter;
    }
  }

  /// Padding used by the cue icon for [edge].
  static EdgeInsets scrollCueIconPadding(MatrixScrollCueEdge edge) {
    switch (edge) {
      case MatrixScrollCueEdge.left:
        return const EdgeInsets.only(left: AppSpacing.sm);
      case MatrixScrollCueEdge.right:
        return const EdgeInsets.only(right: AppSpacing.sm);
      case MatrixScrollCueEdge.top:
        return const EdgeInsets.only(top: AppSpacing.sm);
      case MatrixScrollCueEdge.bottom:
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
