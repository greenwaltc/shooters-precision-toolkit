import 'package:flutter/material.dart';

import '../tokens/app_borders.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Lightly tinted container used to visually group related form fields
/// (e.g. each factor's name + states). Pure styling shell — callers stack
/// their own children inside.
class GroupedFieldPanel extends StatelessWidget {
  const GroupedFieldPanel({
    super.key,
    required this.child,
    this.outerPadding = const EdgeInsets.all(AppSpacing.md),
    this.innerPadding = AppSpacing.groupedPanel,
  });

  final Widget child;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsetsGeometry innerPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: outerPadding,
      child: Container(
        padding: innerPadding,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: scheme.outline,
            width: AppBorders.regular,
          ),
          borderRadius: AppRadius.mdRadius,
        ),
        child: child,
      ),
    );
  }
}
