// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/project_configuration.dart';
import '../styles/app_design.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';

/// Sizing rules for app-bar branding, reading its art and copy from
/// [BrandConfiguration] and its dimensions from [AppDesign].
abstract final class AppBrandAssets {
  static BrandConfiguration get _brand =>
      ProjectConfiguration.current.brand;

  static String get bannerLogo => _brand.bannerLogoAsset;

  static String get compactIcon => _brand.compactLogoAsset;

  /// Screen-reader label for banner and compact logo images.
  static String get logoSemanticLabel => _brand.appTitle;

  /// Tagline rendered beneath the logo on the projects banner.
  static String get projectsSubtext => _brand.tagline;

  static double get bannerAspectRatio => _brand.bannerLogoAspectRatio;

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
        style: AppTextStyles.bannerTagline(context),
      ),
      textDirection: Directionality.of(context),
      maxLines: AppDesign.homeBannerTaglineMaxLines,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);

    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Width reserved for projects-banner actions when estimating tagline wrap.
  static double bannerActionsReserve() {
    var reserve = AppDesign.homeBannerHelpActionsReserve;
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
  factory ProjectsBannerMetrics.of(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final taglineHeight = AppBrandAssets.measureTaglineHeight(
      context: context,
      maxWidth: math.max(
        AppDesign.homeBannerMinTaglineWidth,
        viewport.width - AppBrandAssets.bannerActionsReserve(),
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
          style: AppTextStyles.bannerTagline(context),
          maxLines: AppDesign.homeBannerTaglineMaxLines,
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

/// Standard app-bar title row: brand mark plus a page-specific label.
class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({super.key, required this.label});

  final String label;

  static const double logoHeight = AppDesign.appBarLogoHeight;

  /// App-bar height that fits [logoHeight]. Pages that host an [AppBrandTitle]
  /// must apply this as their `AppBar.toolbarHeight`.
  static const double toolbarHeight = AppDesign.appBarBrandedHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final logoWidth = AppBrandAssets.logoSlotWidth(
          availableWidth: maxWidth,
          height: logoHeight,
        );
        final labelMaxWidth = maxWidth - logoWidth - AppSpacing.sm;

        if (labelMaxWidth <= 0) {
          return AppBrandTitleLogo(height: logoHeight, maxWidth: maxWidth);
        }

        return Row(
          children: [
            AppBrandTitleLogo(height: logoHeight, maxWidth: logoWidth),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        );
      },
    );
  }
}
