import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../foundation/behavior_policy.dart';
import '../foundation/external_links.dart';
import '../l10n/app_copy.dart';
import 'help/help_instructions.dart';
import 'navigation/app_routes.dart';
import 'theme/app_design.dart';
import 'theme/layout/app_layout.dart';
import 'workspace_exit.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

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

  /// Authenticated app bars share the same save-and-sign-out operation.
  /// Standalone workspace previews/tests can omit the session provider.
  static List<AppBarActionItem> signOutActions(BuildContext context) {
    final operation = context.read<WorkspaceExit?>();
    if (operation == null) {
      return const [];
    }
    return [
      AppBarActionItem(
        label: context.l10n.signOut,
        icon: Icons.logout,
        tooltip: context.l10n.signOut,
        onPressed: () => unawaited(operation.run(context)),
      ),
    ];
  }

  /// Builds the widgets for [AppBar.actions].
  static List<Widget> build(
    BuildContext context, {
    required AppLayoutMetrics layout,
    required List<AppBarActionItem> items,
    bool hasLeading = false,
  }) {
    if (items.isEmpty) {
      return const [];
    }

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
        tooltip: context.l10n.menu,
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
      label: context.l10n.instructions,
      icon: Icons.menu_book_outlined,
      tooltip: context.l10n.instructions,
      filledInline: true,
      onPressed: () => showHelpInstructionsSheet(context),
    );
  }

  static AppBarActionItem contact(BuildContext context) => AppBarActionItem(
    label: context.l10n.contact,
    icon: Icons.contact_mail_outlined,
    tooltip: context.l10n.contact,
    filledInline: true,
    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.contact),
  );

  static final donationsUrl = Uri.https(
    BehaviorPolicy.donationsOrigin,
    BehaviorPolicy.donationsPath,
  );

  static AppBarActionItem donations(BuildContext context) => AppBarActionItem(
    label: context.l10n.donations,
    icon: Icons.volunteer_activism_outlined,
    tooltip: context.l10n.donations,
    filledInline: true,
    onPressed: () async {
      final links = context.read<ExternalLinks>();
      var opened = false;
      try {
        opened = await links.open(donationsUrl);
      } catch (_) {
        // Keep the app usable if the platform has no link handler.
      }
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.unableToOpenPayPalPleaseTryAgain),
          ),
        );
      }
    },
  );

  static Widget _inlineAction(BuildContext context, AppBarActionItem item) {
    if (item.filledInline) {
      return Padding(
        padding: AppDesign.appBarFilledActionMargin,
        child: Tooltip(
          message: item.tooltip ?? item.label,
          excludeFromSemantics: true,
          child: FilledButton(
            onPressed: item.onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppDesign.appBarFilledActionMinHeight),
              padding: AppDesign.appBarFilledActionPadding,
              tapTargetSize: MaterialTapTargetSize.padded,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(item.label),
          ),
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
    final titleWithInline = (screenWidth - leadingWidth - inlineWidth).clamp(
      0.0,
      screenWidth,
    );
    final compact = layout.preferCompactChrome;

    // Reserve room for the brand/title at every breakpoint, including tablets
    // and enlarged text. Filled actions can otherwise crowd the toolbar.
    final collapsed =
        items.isNotEmpty &&
        inlineWidth > AppBarActionBar.iconActionWidth &&
        (inlineWidth > screenWidth / 2 ||
            !_rowBrandTitleFits(titleWithInline, compact: compact));

    final actionsWidth = collapsed
        ? AppBarActionBar.iconActionWidth
        : inlineWidth;
    final titleMaxWidth = (screenWidth - leadingWidth - actionsWidth).clamp(
      0.0,
      screenWidth,
    );

    return AppBarActionsMetrics(
      collapsed: collapsed,
      actionsWidth: actionsWidth,
      titleMaxWidth: titleMaxWidth,
    );
  }

  /// Whether [titleWidth] can hold the logo beside a short single-line label.
  static bool _rowBrandTitleFits(double titleWidth, {required bool compact}) {
    final logoHeight = compact
        ? AppDesign.appBarLogoHeightCompact
        : AppDesign.appBarLogoHeight;
    final gap = compact
        ? AppDesign.appBarBrandTitleGapCompact
        : AppDesign.appBarBrandTitleGap;
    // Compact logo is square at [logoHeight]; require a modest label slot too.
    const minLabelSlot = 64.0;
    return titleWidth >= logoHeight + gap + minLabelSlot;
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
