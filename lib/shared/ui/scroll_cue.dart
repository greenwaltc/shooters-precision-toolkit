// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import 'theme/components/scroll_cue_style.dart';

/// Non-interactive edge overlay that hints more content is scrollable.
class ScrollCue extends StatelessWidget {
  /// Creates a scroll hint for [edge] using the surrounding theme.
  const ScrollCue({super.key, required this.edge});

  /// Edge where the cue is painted.
  final ScrollCueEdge edge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          child: Center(
            child: Icon(
              ScrollCueStyle.icon(edge),
              size: ScrollCueStyle.iconSize,
              color: scheme.onSurfaceVariant.withValues(
                alpha: ScrollCueStyle.iconOpacity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
