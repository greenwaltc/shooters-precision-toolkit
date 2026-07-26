// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../help/help_instructions.dart';
import '../styles/app_design.dart';
import '../styles/layout/app_layout.dart';

/// One declarative app-bar action that can render inline or inside an overflow
/// menu when the bar is too narrow to show every control.
class AppBarActionItem {
  const AppBarActionItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filledInline = false,
  });

  /// Menu and accessibility label.
  final String label;

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  /// When true, the inline control is a compact filled (primary) button —
  /// purple background with on-primary lettering — instead of an icon button.
  final bool filledInline;
}

/// Builds app-bar [actions], collapsing them into a hamburger [PopupMenuButton]
/// on mobile when the inline controls would steal too much title space.
abstract final class AppBarActionBar {
  /// Estimated width of a standard [IconButton] app-bar action.
  static const double iconActionWidth = kMinInteractiveDimension;

  /// Builds the widgets for [AppBar.actions].
  static List<Widget> build(
    BuildContext context, {
    required AppLayoutMetrics layout,
    required List<AppBarActionItem> items,
    bool hasLeading = false,
  }) {
    if (items.isEmpty) return const [];

    final metrics = AppBarActionsMetrics.of(
      context,
      layout: layout,
      items: items,
      hasLeading: hasLeading,
    );

    if (!metrics.collapsed) {
      return [for (final item in items) _inlineAction(context, item)];
    }

    return [
      PopupMenuButton<int>(
        tooltip: 'Menu',
        position: PopupMenuPosition.under,
        icon: const Icon(Icons.menu),
        onSelected: (index) => items[index].onPressed(),
        itemBuilder: (context) => [
          for (var i = 0; i < items.length; i++)
            PopupMenuItem<int>(
              value: i,
              child: Row(
                children: [
                  Icon(items[i].icon),
                  const SizedBox(width: AppDesign.space12),
                  Expanded(child: Text(items[i].label)),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  /// Instructions action bound to [context] for opening the help sheet.
  static AppBarActionItem instructions(BuildContext context) {
    return AppBarActionItem(
      label: 'Instructions',
      icon: Icons.menu_book_outlined,
      tooltip: 'Instructions',
      filledInline: true,
      onPressed: () => showHelpInstructionsSheet(context),
    );
  }

  static Widget _inlineAction(BuildContext context, AppBarActionItem item) {
    if (item.filledInline) {
      return Padding(
        padding: AppDesign.appBarFilledActionMargin,
        child: FilledButton(
          onPressed: item.onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppDesign.appBarFilledActionMinHeight),
            padding: AppDesign.appBarFilledActionPadding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(item.label),
        ),
      );
    }

    return IconButton(
      tooltip: item.tooltip ?? item.label,
      onPressed: item.onPressed,
      icon: Icon(item.icon),
    );
  }
}

/// Width / collapse decision for a set of app-bar actions.
@immutable
class AppBarActionsMetrics {
  const AppBarActionsMetrics({
    required this.collapsed,
    required this.actionsWidth,
    required this.titleMaxWidth,
  });

  final bool collapsed;
  final double actionsWidth;
  final double titleMaxWidth;

  factory AppBarActionsMetrics.of(
    BuildContext context, {
    required AppLayoutMetrics layout,
    required List<AppBarActionItem> items,
    bool hasLeading = false,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leadingWidth = hasLeading ? kMinInteractiveDimension : 0.0;
    final inlineWidth = _estimateInlineWidth(context, items);
    final titleWithInline =
        (screenWidth - leadingWidth - inlineWidth).clamp(0.0, screenWidth);

    // Collapse on mobile when inline actions would leave the brand title too
    // narrow for logo + label in a row, and collapsing to one menu control
    // actually frees horizontal space.
    final collapsed =
        layout.isMobile &&
        items.isNotEmpty &&
        inlineWidth > AppBarActionBar.iconActionWidth &&
        !_rowBrandTitleFits(titleWithInline);

    final actionsWidth =
        collapsed ? AppBarActionBar.iconActionWidth : inlineWidth;
    final titleMaxWidth =
        (screenWidth - leadingWidth - actionsWidth).clamp(0.0, screenWidth);

    return AppBarActionsMetrics(
      collapsed: collapsed,
      actionsWidth: actionsWidth,
      titleMaxWidth: titleMaxWidth,
    );
  }

  /// Whether [titleWidth] can hold the logo beside a short single-line label.
  static bool _rowBrandTitleFits(double titleWidth) {
    const logoHeight = AppDesign.appBarLogoHeight;
    // Compact logo is square at [logoHeight]; require a modest label slot too.
    const minLabelSlot = 64.0;
    return titleWidth >=
        logoHeight + AppDesign.appBarBrandTitleGap + minLabelSlot;
  }

  static double _estimateInlineWidth(
    BuildContext context,
    List<AppBarActionItem> items,
  ) {
    var total = 0.0;
    for (final item in items) {
      if (item.filledInline) {
        final painter = TextPainter(
          text: TextSpan(
            text: item.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: AppDesign.labelWeight,
              letterSpacing: AppDesign.labelTracking,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        total +=
            painter.width +
            AppDesign.appBarFilledActionPadding.horizontal +
            AppDesign.appBarFilledActionMargin.horizontal;
        painter.dispose();
      } else {
        total += AppBarActionBar.iconActionWidth;
      }
    }
    return total;
  }
}
