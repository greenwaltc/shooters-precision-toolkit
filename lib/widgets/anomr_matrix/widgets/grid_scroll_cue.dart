// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/components/matrix_grid_style.dart';

/// Non-interactive edge overlay that hints more matrix content is scrollable.
class GridScrollCue extends StatelessWidget {
  const GridScrollCue({super.key, required this.edge, required this.scheme});

  /// Edge where the cue is painted.
  final MatrixScrollCueEdge edge;

  /// Active color scheme used to harmonize the cue with the page surface.
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isHorizontal =
        edge == MatrixScrollCueEdge.left || edge == MatrixScrollCueEdge.right;

    return IgnorePointer(
      child: SizedBox(
        width: isHorizontal ? MatrixGridStyle.scrollCueExtent : double.infinity,
        height: isHorizontal
            ? double.infinity
            : MatrixGridStyle.scrollCueExtent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: MatrixGridStyle.scrollCueGradient(
              edge: edge,
              surface: scheme.surface,
            ),
          ),
          child: Align(
            alignment: MatrixGridStyle.scrollCueIconAlignment(edge),
            child: Padding(
              padding: MatrixGridStyle.scrollCueIconPadding(edge),
              child: Icon(
                MatrixGridStyle.scrollCueIcon(edge),
                size: 22,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
