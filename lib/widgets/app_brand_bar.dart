// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/project_configuration.dart';
import '../styles/app_design.dart';
import '../styles/layout/app_layout.dart';
import '../styles/tokens/app_headings.dart';

/// Sizing rules for app-bar branding, reading its art and copy from
/// [BrandConfiguration] and its dimensions from [AppDesign].
abstract final class AppBrandAssets {
  static BrandConfiguration get _brand => ProjectConfiguration.current.brand;

  static String get bannerLogo => _brand.bannerLogoAsset;

  static String get compactIcon => _brand.compactLogoAsset;

  /// Screen-reader label for banner and compact logo images.
  static String get logoSemanticLabel => _brand.appTitle;

  /// Tagline rendered beneath the logo on the projects banner.
  static String get projectsSubtext => _brand.tagline;

  static double get bannerAspectRatio => _brand.bannerLogoAspectRatio;

  /// Whether the projects banner is laid out at a mobile width.
  static bool isMobileBanner(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppLayoutMetrics.mobileBreakpoint;
  }

  /// Tagline style: h4 on mobile, h2 on larger viewports.
  static TextStyle? taglineStyle(BuildContext context) {
    return isMobileBanner(context)
        ? AppHeadings.h4(context)
        : AppHeadings.h2(context);
  }

  /// Tagline wrap limit for the current viewport.
  static int taglineMaxLines(BuildContext context) {
    return isMobileBanner(context)
        ? AppDesign.homeBannerTaglineMaxLinesMobile
        : AppDesign.homeBannerTaglineMaxLines;
  }

  /// Returns true when [availableWidth] cannot fit [bannerLogo] at [height].
  static bool shouldUseCompactLogo({
    required double availableWidth,
    required double height,
  }) {
    if (!availableWidth.isFinite || availableWidth <= 0) return false;
    return availableWidth < height * bannerAspectRatio;
  }

  /// Height of the wrapped tagline at [maxWidth] under the current text scale.
  static double measureTaglineHeight({
    required BuildContext context,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: projectsSubtext,
        style: taglineStyle(context),
      ),
      textDirection: Directionality.of(context),
      maxLines: taglineMaxLines(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);

    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Width reserved for projects-banner actions when estimating tagline wrap.
  static double bannerActionsReserve({bool includeHelpAction = true}) {
    var reserve = 0.0;
    if (includeHelpAction) {
      reserve += AppDesign.homeBannerHelpActionsReserve;
    }
    if (ProjectConfiguration.current.featureFlags.isEnabled(
      FeatureFlag.themeModeToggle,
    )) {
      reserve += AppDesign.homeBannerThemeToggleActionsReserve;
    }
    return reserve;
  }

  /// Slot width for a logo laid out in [availableWidth] at [height].
  static double logoSlotWidth({
    required double availableWidth,
    required double height,
  }) {
    final useCompact = shouldUseCompactLogo(
      availableWidth: availableWidth,
      height: height,
    );
    return useCompact ? height : height * bannerAspectRatio;
  }
}

/// Banner or compact app icon, chosen from the space available at [height].
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    required this.height,
    this.alignment = Alignment.center,
  });

  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompact = AppBrandAssets.shouldUseCompactLogo(
          availableWidth: constraints.maxWidth,
          height: height,
        );
        final asset = useCompact
            ? AppBrandAssets.compactIcon
            : AppBrandAssets.bannerLogo;

        return Align(
          alignment: alignment,
          child: Image.asset(
            asset,
            height: height,
            fit: BoxFit.contain,
            alignment: alignment,
            semanticLabel: AppBrandAssets.logoSemanticLabel,
          ),
        );
      },
    );
  }
}

/// Logo height and toolbar height the projects banner needs in a viewport.
@immutable
class ProjectsBannerMetrics {
  const ProjectsBannerMetrics({
    required this.logoHeight,
    required this.toolbarHeight,
  });

  /// Measures the banner against the viewport in [context].
  ///
  /// The logo keeps its full [AppDesign.homeBannerLogoHeight] whenever the
  /// viewport is tall enough; on shorter screens it shrinks (never past
  /// [AppDesign.homeBannerMinLogoHeight]) so the page body keeps a workable
  /// amount of room beneath the banner.
  ///
  /// Pass [includeHelpAction]: false when Instructions is shown as a FAB
  /// instead of an app-bar action so the tagline can use the extra width.
  factory ProjectsBannerMetrics.of(
    BuildContext context, {
    bool includeHelpAction = true,
  }) {
    final viewport = MediaQuery.sizeOf(context);
    final taglineHeight = AppBrandAssets.measureTaglineHeight(
      context: context,
      maxWidth: math.max(
        AppDesign.homeBannerMinTaglineWidth,
        viewport.width -
            AppBrandAssets.bannerActionsReserve(
              includeHelpAction: includeHelpAction,
            ),
      ),
    );

    // Everything in the toolbar other than the logo itself.
    final chrome =
        AppDesign.homeBannerTaglineGap +
        taglineHeight +
        AppDesign.appBarBrandingPadding * 2;

    final logoHeight =
        viewport.height >= AppDesign.homeBannerFullSizeViewportHeight
        ? AppDesign.homeBannerLogoHeight
        : (viewport.height - chrome - AppDesign.homeBannerMinBodyHeight).clamp(
            AppDesign.homeBannerMinLogoHeight,
            AppDesign.homeBannerLogoHeight,
          );

    return ProjectsBannerMetrics(
      logoHeight: logoHeight,
      toolbarHeight: logoHeight + chrome,
    );
  }

  final double logoHeight;
  final double toolbarHeight;
}

/// Projects-page banner: logo (or compact icon) with tagline directly beneath.
class AppProjectsBannerTitle extends StatelessWidget {
  const AppProjectsBannerTitle({super.key, required this.logoHeight});

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBrandLogo(height: logoHeight, alignment: Alignment.center),
        const SizedBox(height: AppDesign.homeBannerTaglineGap),
        Text(
          AppBrandAssets.projectsSubtext,
          textAlign: TextAlign.center,
          style: AppBrandAssets.taglineStyle(context),
          maxLines: AppBrandAssets.taglineMaxLines(context),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Home-route app bar whose height is derived from the banner content.
///
/// [metrics] must be measured by the caller because [preferredSize] is read
/// before this widget builds and so has no context of its own.
///
/// Transparent by design so the Projects atmosphere can show through when the
/// scaffold uses [Scaffold.extendBodyBehindAppBar].
class ProjectsBannerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ProjectsBannerAppBar({
    super.key,
    required this.metrics,
    required this.actions,
  });

  final ProjectsBannerMetrics metrics;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(metrics.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: metrics.toolbarHeight,
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      title: AppProjectsBannerTitle(logoHeight: metrics.logoHeight),
      actions: actions,
    );
  }
}

/// Left-aligned logo for standard app bars on non-home routes.
class AppBrandTitleLogo extends StatelessWidget {
  const AppBrandTitleLogo({
    super.key,
    this.height = AppDesign.appBarLogoHeight,
    required this.maxWidth,
  });

  final double height;

  /// Horizontal space available to the logo (typically the app-bar title width).
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final slotWidth = AppBrandAssets.logoSlotWidth(
      availableWidth: maxWidth,
      height: height,
    );

    return SizedBox(
      width: slotWidth,
      height: height,
      child: AppBrandLogo(height: height, alignment: Alignment.centerLeft),
    );
  }
}

/// Layout metrics for [AppBrandTitle]: row vs stacked logo/label and the
/// toolbar height that fits the chosen arrangement.
@immutable
class AppBrandTitleMetrics {
  const AppBrandTitleMetrics({
    required this.stacked,
    required this.toolbarHeight,
  });

  final bool stacked;
  final double toolbarHeight;

  /// App-bar height that fits the logo in the default horizontal layout.
  static const double rowToolbarHeight = AppDesign.appBarBrandedHeight;

  /// Decides whether [label] fits beside the logo in [titleMaxWidth].
  factory AppBrandTitleMetrics.of(
    BuildContext context, {
    required String label,
    required double titleMaxWidth,
  }) {
    const logoHeight = AppDesign.appBarLogoHeight;
    final logoWidth = AppBrandAssets.logoSlotWidth(
      availableWidth: titleMaxWidth,
      height: logoHeight,
    );
    final labelMaxWidth =
        titleMaxWidth - logoWidth - AppDesign.appBarBrandTitleGap;

    final fitsBeside =
        labelMaxWidth > 0 &&
        !_labelExceedsWidth(
          context: context,
          label: label,
          maxWidth: labelMaxWidth,
          style: AppHeadings.h2(context),
        );

    if (fitsBeside) {
      return const AppBrandTitleMetrics(
        stacked: false,
        toolbarHeight: rowToolbarHeight,
      );
    }

    final labelHeight = _measureLabelHeight(
      context: context,
      label: label,
      maxWidth: titleMaxWidth,
      maxLines: AppDesign.appBarBrandLabelMaxLinesStacked,
      style: AppHeadings.h2(context),
    );

    final toolbarHeight =
        AppDesign.appBarBrandingPadding * 2 +
        logoHeight +
        AppDesign.appBarBrandStackedGap +
        labelHeight;

    return AppBrandTitleMetrics(stacked: true, toolbarHeight: toolbarHeight);
  }

  static bool _labelExceedsWidth({
    required BuildContext context,
    required String label,
    required double maxWidth,
    required TextStyle? style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final exceeds = painter.didExceedMaxLines;
    painter.dispose();
    return exceeds;
  }

  static double _measureLabelHeight({
    required BuildContext context,
    required String label,
    required double maxWidth,
    required int maxLines,
    required TextStyle? style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: math.max(0, maxWidth));
    final height = painter.height;
    painter.dispose();
    return height;
  }
}

/// Standard app-bar title: brand mark plus a page-specific label.
///
/// When [metrics.stacked] is true the logo sits above the label (start-aligned)
/// so the label is not forced into a single-line ellipsis beside a wide mark.
class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({
    super.key,
    required this.label,
    required this.metrics,
  });

  final String label;
  final AppBrandTitleMetrics metrics;

  static const double logoHeight = AppDesign.appBarLogoHeight;

  /// Default (row) app-bar height. Prefer [AppBrandTitleMetrics.toolbarHeight]
  /// when the label may need to stack beneath the logo.
  static const double toolbarHeight = AppBrandTitleMetrics.rowToolbarHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        if (metrics.stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBrandTitleLogo(height: logoHeight, maxWidth: maxWidth),
              const SizedBox(height: AppDesign.appBarBrandStackedGap),
              Text(
                label,
                style: AppHeadings.h2(context),
                maxLines: AppDesign.appBarBrandLabelMaxLinesStacked,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }

        final logoWidth = AppBrandAssets.logoSlotWidth(
          availableWidth: maxWidth,
          height: logoHeight,
        );
        final labelMaxWidth =
            maxWidth - logoWidth - AppDesign.appBarBrandTitleGap;

        if (labelMaxWidth <= 0) {
          return AppBrandTitleLogo(height: logoHeight, maxWidth: maxWidth);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppBrandTitleLogo(height: logoHeight, maxWidth: logoWidth),
            const SizedBox(width: AppDesign.appBarBrandTitleGap),
            Expanded(
              child: Text(
                label,
                style: AppHeadings.h2(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
