// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/components/scroll_cue_style.dart';

/// Non-interactive edge overlay that hints more content is scrollable.
class GridScrollCue extends StatelessWidget {
  const GridScrollCue({super.key, required this.edge, required this.scheme});

  /// Edge where the cue is painted.
  final ScrollCueEdge edge;

  /// Active color scheme used to harmonize the cue with the page surface.
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isHorizontal =
        edge == ScrollCueEdge.left || edge == ScrollCueEdge.right;

    return IgnorePointer(
      child: SizedBox(
        width: isHorizontal ? ScrollCueStyle.extent : double.infinity,
        height: isHorizontal ? double.infinity : ScrollCueStyle.extent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ScrollCueStyle.gradient(
              edge: edge,
              surface: scheme.surface,
            ),
          ),
          child: Align(
            alignment: ScrollCueStyle.iconAlignment(edge),
            child: Padding(
              padding: ScrollCueStyle.iconPadding(edge),
              child: Icon(
                ScrollCueStyle.icon(edge),
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
