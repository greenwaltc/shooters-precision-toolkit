import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../foundation/behavior_policy.dart';
import '../foundation/external_links.dart';
import '../l10n/app_copy.dart';
import 'app_brand_bar.dart';
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
  /// Describes one banner action for inline display or an overflow menu.
  ///
  /// Set [filledInline] to show a text button in the banner. Set [isDonation]
  /// for the accent style and higher priority when space runs out.
  const AppBarActionItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filledInline = false,
    this.isDonation = false,
  });

  /// Menu and accessibility label.
  final String label;

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  /// When true, the inline control is a compact filled (primary) button —
  /// purple background with on-primary lettering — instead of an icon button.
  final bool filledInline;

  /// Whether to use the donation style and keep this action inline longest.
  final bool isDonation;
}

/// App bar actions that move into a menu when the title needs more room.
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

  /// Builds inline actions and an overflow menu for [AppBar.actions].
  ///
  /// Set [hasTitleStatus] when the title needs room for a save indicator.
  /// Pass the app bar's [titleSpacing] if it differs from the standard.
  static List<Widget> build(
    BuildContext context, {
    required AppLayoutMetrics layout,
    required List<AppBarActionItem> items,
    bool hasLeading = false,
    bool hasTitleStatus = false,
    double titleSpacing = AppDesign.appBarTitleSpacing,
  }) {
    if (items.isEmpty) {
      return const [];
    }

    final metrics = AppBarActionsMetrics.of(
      context,
      layout: layout,
      items: items,
      hasLeading: hasLeading,
      hasTitleStatus: hasTitleStatus,
      titleSpacing: titleSpacing,
    );

    final overflow = metrics.overflowItems;
    return [
      for (final item in metrics.inlineItems) _inlineAction(context, item),
      if (overflow.isNotEmpty)
        PopupMenuButton<AppBarActionItem>(
          tooltip: context.l10n.menu,
          position: PopupMenuPosition.under,
          icon: const Icon(Icons.menu),
          onSelected: (item) => item.onPressed(),
          itemBuilder: (context) => [
            for (final item in overflow)
              PopupMenuItem<AppBarActionItem>(
                value: item,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kMinInteractiveDimension,
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon),
                      const SizedBox(width: AppDesign.space12),
                      Expanded(child: Text(item.label)),
                    ],
                  ),
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

  /// Creates the navigation action that opens the public Contact page.
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

  /// Creates the action that opens the configured donation link.
  static AppBarActionItem donations(BuildContext context) => AppBarActionItem(
    label: context.l10n.donations,
    icon: Icons.volunteer_activism_outlined,
    tooltip: context.l10n.donations,
    filledInline: true,
    isDonation: true,
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
    if (item.isDonation) {
      return _DonateButton(item: item);
    }
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
              visualDensity: VisualDensity.standard,
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

/// The action placement and title width for one app bar.
@immutable
class AppBarActionsMetrics {
  const AppBarActionsMetrics._({
    required this.inlineItems,
    required this.overflowItems,
    required this.actionsWidth,
    required this.titleMaxWidth,
  });

  /// Actions drawn in the banner, in display order.
  final List<AppBarActionItem> inlineItems;

  /// Actions available from the menu. Donate appears first if it cannot fit inline.
  final List<AppBarActionItem> overflowItems;

  final double actionsWidth;
  final double titleMaxWidth;

  /// Measures the actions at the current text scale and preserves room for branding.
  ///
  /// Set [hasTitleStatus] when the title needs room for a save indicator.
  /// Pass the app bar's [titleSpacing] if it differs from the standard.
  ///
  /// If all actions cannot fit inline, tries keeping Donate beside the menu
  /// before putting it in the menu with the other actions.
  factory AppBarActionsMetrics.of(
    BuildContext context, {
    required AppLayoutMetrics layout,
    required List<AppBarActionItem> items,
    bool hasLeading = false,
    bool hasTitleStatus = false,
    double titleSpacing = AppDesign.appBarTitleSpacing,
  }) {
    final safeArea = MediaQuery.paddingOf(context).horizontal;
    final screenWidth = layout.width - safeArea;
    final leadingWidth = hasLeading ? kToolbarHeight : 0.0;
    final fullWidth = _estimateInlineWidth(context, items);
    final donate = items.where((item) => item.isDonation).toList();
    final regular = items.where((item) => !item.isDonation).toList();
    final menuWidth = AppBarActionBar.iconActionWidth;
    final logoHeight = AppBrandAssets.heightFor(layout);
    final logoWidth = layout.isMobile
        ? logoHeight
        : logoHeight * AppBrandAssets.bannerAspectRatio;
    final statusWidth = hasTitleStatus
        ? kMinInteractiveDimension + AppDesign.space8
        : 0.0;
    final gap = layout.isMobile
        ? AppDesign.appBarBrandTitleGapCompact
        : AppDesign.appBarBrandTitleGap;
    final widthWithTitle = screenWidth - leadingWidth - 2 * titleSpacing;
    final donateAndMenuWidth =
        _estimateInlineWidth(context, donate) +
        (regular.isEmpty ? 0 : menuWidth);

    final List<AppBarActionItem> inline;
    final List<AppBarActionItem> overflow;
    if (fullWidth <= screenWidth / 2 &&
        fullWidth <=
            widthWithTitle -
                logoWidth -
                gap -
                AppDesign.appBarMinimumTitleLabelWidth -
                statusWidth) {
      inline = [...donate, ...regular];
      overflow = const [];
    } else if (donate.isNotEmpty &&
        donateAndMenuWidth <=
            widthWithTitle -
                logoHeight -
                (hasTitleStatus ? gap + statusWidth : 0)) {
      inline = donate;
      overflow = regular;
    } else {
      inline = const [];
      overflow = [...donate, ...regular];
    }
    final actionsWidth =
        _estimateInlineWidth(context, inline) +
        (overflow.isEmpty ? 0 : menuWidth);
    return AppBarActionsMetrics._(
      inlineItems: List.unmodifiable(inline),
      overflowItems: List.unmodifiable(overflow),
      actionsWidth: actionsWidth,
      titleMaxWidth: (widthWithTitle - actionsWidth).clamp(0.0, layout.width),
    );
  }

  static double _estimateInlineWidth(
    BuildContext context,
    List<AppBarActionItem> items,
  ) {
    var total = 0.0;
    for (final item in items) {
      if (item.filledInline) {
        final painter = TextPainter(
          text: TextSpan(text: item.label, style: _actionLabelStyle(context)),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final padding = item.isDonation
            ? AppDesign.donateActionPadding
            : AppDesign.appBarFilledActionPadding;
        final margin = item.isDonation
            ? AppDesign.donateActionMargin
            : AppDesign.appBarFilledActionMargin;
        total +=
            (painter.width + padding.horizontal)
                .clamp(AppBarActionBar.iconActionWidth, double.infinity)
                .ceilToDouble() +
            margin.horizontal;
        painter.dispose();
      } else {
        total += AppBarActionBar.iconActionWidth;
      }
    }
    return total;
  }
}

TextStyle? _actionLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: AppDesign.labelWeight,
      letterSpacing: AppDesign.labelTracking,
    );

/// A Material button with a sliding magenta and cyan background.
class _DonateButton extends StatelessWidget {
  const _DonateButton({required this.item});

  final AppBarActionItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Both ends of the gradient must stay readable under the white label.
    final scrim = Colors.black.withValues(
      alpha: AppDesign.donateGradientScrimOpacity,
    );
    final magenta = Color.alphaBlend(scrim, AppDesign.donateGradientMagenta);
    final cyan = Color.alphaBlend(scrim, AppDesign.donateGradientCyan);
    final silver = Color.alphaBlend(scrim, AppDesign.donateGradientSilver);
    final radius = BorderRadius.circular(AppDesign.donateButtonRadius);
    return Padding(
      padding: AppDesign.donateActionMargin,
      child: Tooltip(
        message: item.tooltip ?? item.label,
        excludeFromSemantics: true,
        child: FilledButton(
          onPressed: item.onPressed,
          style:
              FilledButton.styleFrom(
                textStyle: _actionLabelStyle(context),
                foregroundColor: Colors.white,
                backgroundColor: magenta,
                elevation: AppDesign.elevationFloating,
                shadowColor: scheme.shadow,
                minimumSize: const Size(
                  kMinInteractiveDimension,
                  kMinInteractiveDimension,
                ),
                padding: AppDesign.donateActionPadding,
                visualDensity: VisualDensity.standard,
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(borderRadius: radius),
              ).copyWith(
                backgroundBuilder: (context, states, child) {
                  final highlighted =
                      states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused);
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: highlighted ? 1 : 0),
                    duration: reduceMotion
                        ? Duration.zero
                        : AppDesign.donateGradientDuration,
                    curve: AppDesign.motionCurve,
                    child: child,
                    builder: (context, phase, child) {
                      // The narrow highlight appears only during the sweep.
                      final sheen = 4 * phase * (1 - phase);
                      return Ink(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment(-1 - 2 * phase, -1 - 2 * phase),
                            end: Alignment(3 - 2 * phase, 3 - 2 * phase),
                            colors: [
                              magenta,
                              Color.lerp(magenta, cyan, 0.88)!,
                              Color.lerp(cyan, silver, sheen)!,
                              Color.lerp(cyan, magenta, 0.12)!,
                              magenta,
                            ],
                            stops: const [0, 0.47, 0.51, 0.55, 1],
                          ),
                        ),
                        child: child,
                      );
                    },
                  );
                },
              ),
          child: Text(
            item.label.toUpperCase(),
            semanticsLabel: item.label,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
