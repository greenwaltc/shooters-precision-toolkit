import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Visual variant for [OutlinedSurfaceCard].
enum OutlinedSurfaceVariant {
  /// Pure surface background (used for the results chart card and the
  /// project list tile).
  surface,

  /// Subtle tinted background derived from `surfaceContainerHighest`,
  /// reserved for emphasized "summary" surfaces (header summary card).
  tinted,
}

/// Flat outlined card used as the visual container for grouped content.
///
/// Replaces hand-rolled `Card` + `RoundedRectangleBorder(side: ...)`
/// configurations scattered around the app. Variants differ only in fill;
/// shape, elevation, and border are consistent across all surface cards so
/// they read as one family.
class OutlinedSurfaceCard extends StatelessWidget {
  const OutlinedSurfaceCard({
    super.key,
    required this.child,
    this.variant = OutlinedSurfaceVariant.surface,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius = AppRadius.lgRadius,
    this.borderColor,
  });

  final Widget child;
  final OutlinedSurfaceVariant variant;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Optional border color override. Defaults to `colorScheme.outlineVariant`.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: switch (variant) {
        OutlinedSurfaceVariant.surface => scheme.surface,
        OutlinedSurfaceVariant.tinted =>
          scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      },
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor ?? scheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
