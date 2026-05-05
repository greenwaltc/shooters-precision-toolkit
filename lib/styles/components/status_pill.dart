// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../tokens/app_opacity.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Small rounded pill that pairs an icon with a label.
///
/// Used by per-factor conclusion rows (significant / not detected / etc.).
/// All visual decisions (fill alpha, border alpha, radius, sizing) live
/// here so callers only choose the semantic [color] and the contents.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.scale = 1.0,
    this.iconSize,
    this.fontSize,
  });

  final String label;
  final IconData icon;

  /// Semantic color (significant=error, notDetected=primary, marginal=tertiary,
  /// insufficient=onSurfaceVariant). Used for the icon, label, fill (with
  /// [AppOpacity.pillFill]), and border (with [AppOpacity.pillBorder]).
  final Color color;

  /// Optional scale factor used by responsive surfaces. Defaults to `1.0`.
  final double scale;

  /// Override icon size. Defaults to `(font * scale)+4` clamped to a
  /// reasonable range.
  final double? iconSize;

  /// Override label font size. Defaults to the active `labelLarge` size.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scale).clamp(8.0, 14.0),
        vertical: (6 * scale).clamp(5.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.pillFill),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: AppOpacity.pillBorder)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize ?? 16, color: color),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
