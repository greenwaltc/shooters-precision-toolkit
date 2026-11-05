import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'product_configuration.dart';
import 'theme/app_design.dart';
import 'theme/layout/app_layout.dart';
import 'theme/tokens/app_headings.dart';
import 'theme/tokens/app_spacing.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Sizing rules for app-bar branding, reading its art and copy from
/// [BrandConfiguration] and its dimensions from [AppDesign].
abstract final class AppBrandAssets {
  static BrandConfiguration get _brand => BrandConfiguration.defaults;

  /// The asset path for the full-width brand logo.
  static String get bannerLogo => _brand.bannerLogoAsset;

  /// The asset path for the square brand icon used in tight layouts.
  static String get compactIcon => _brand.compactLogoAsset;

  /// Screen-reader label for banner and compact logo images.
  static String get logoSemanticLabel => _brand.appTitle;

  /// Tagline rendered beneath the logo on the projects banner.
  static String get projectsSubtext => _brand.tagline;

  /// The intrinsic width divided by height of the banner logo.
  static double get bannerAspectRatio => _brand.bannerLogoAspectRatio;

  /// The shared logo height in logical pixels for this viewport.
  static double heightFor(AppLayoutMetrics layout) => layout.isMobile
      ? AppDesign.appBarLogoHeightCompact
      : AppDesign.appBarLogoHeight;

  /// Title spacing for project pages that place their logo beside Back.
  static double projectTitleSpacing(
    AppLayoutMetrics layout, {
    required bool hasLeading,
  }) => layout.isMobile && hasLeading
      ? AppDesign.appBarTitleSpacingCompact
      : AppDesign.appBarTitleSpacing;

  /// Whether the projects banner is laid out at a mobile width.
  static bool isMobileBanner(BuildContext context) {
    return AppLayoutMetrics.of(context).isMobile;
  }

  /// Tagline style: h4 on mobile, h2 on larger viewports.
  static TextStyle? taglineStyle(BuildContext context) {
    return isMobileBanner(context)
        ? AppHeadings.h4(context)
        : AppHeadings.h2(context);
  }

  /// Tagline wrap limit for the current viewport.
  static int taglineMaxLines(BuildContext context) {
    if (isMobileLandscapeBanner(context)) {
      return 0;
    }
    return isMobileBanner(context)
        ? AppDesign.homeBannerTaglineMaxLinesMobile
        : AppDesign.homeBannerTaglineMaxLines;
  }

  /// Mobile width in landscape orientation.
  static bool isMobileLandscapeBanner(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppLayoutMetrics.of(context).isMobile && size.height < size.width;
  }

  /// Returns true when [availableWidth] cannot fit [bannerLogo] at [height].
  static bool shouldUseCompactLogo({
    required double availableWidth,
    required double height,
  }) {
    if (!availableWidth.isFinite || availableWidth <= 0) {
      return false;
    }
    return availableWidth < height * bannerAspectRatio;
  }

  /// Height of the wrapped tagline at [maxWidth] under the current text scale.
  static double measureTaglineHeight({
    required BuildContext context,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: projectsSubtext, style: taglineStyle(context)),
      textDirection: Directionality.of(context),
      maxLines: taglineMaxLines(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);

    final height = painter.height;
    painter.dispose();
    return height;
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
  /// Creates a brand image with the requested logical [height] and [alignment].
  const AppBrandLogo({
    super.key,
    required this.height,
    this.alignment = AlignmentDirectional.center,
  });

  final double height;
  final AlignmentGeometry alignment;

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
  /// Sets the Projects banner heights and whether it shows the tagline.
  const ProjectsBannerMetrics({
    required this.logoHeight,
    required this.toolbarHeight,
    this.showTagline = true,
  });

  /// Measures the banner using the same logo height as every other page.
  factory ProjectsBannerMetrics.of(
    BuildContext context, {
    double? actionsWidth,
  }) {
    final layout = AppLayoutMetrics.of(context);
    final logoHeight = AppBrandAssets.heightFor(layout);
    if (layout.isMobile || layout.isDesktop) {
      return ProjectsBannerMetrics(
        logoHeight: logoHeight,
        toolbarHeight: layout.isMobile
            ? AppDesign.appBarBrandedHeightCompact
            : AppDesign.appBarBrandedHeight,
        showTagline: false,
      );
    }

    final taglineHeight = AppBrandAssets.measureTaglineHeight(
      context: context,
      maxWidth: math.max(
        AppDesign.homeBannerMinTaglineWidth,
        layout.width - (actionsWidth ?? 0) - AppSpacing.xl * 2,
      ),
    );
    return ProjectsBannerMetrics(
      logoHeight: logoHeight,
      toolbarHeight:
          AppDesign.appBarBrandedHeight +
          AppDesign.homeBannerTaglineGap +
          taglineHeight,
    );
  }

  final double logoHeight;
  final double toolbarHeight;
  final bool showTagline;
}

/// Projects-page banner: logo (or compact icon) with tagline directly beneath.
class AppProjectsBannerTitle extends StatelessWidget {
  /// Creates the Projects banner title with a logo and optional tagline.
  const AppProjectsBannerTitle({
    super.key,
    required this.logoHeight,
    this.showTagline = true,
  });

  final double logoHeight;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => AppBrandTitleLogo(
            height: logoHeight,
            maxWidth: constraints.maxWidth,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppDesign.homeBannerTaglineGap),
          Text(
            AppBrandAssets.projectsSubtext,
            textAlign: TextAlign.start,
            style: AppBrandAssets.taglineStyle(context),
            maxLines: AppBrandAssets.taglineMaxLines(context),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
  /// Creates the Projects app bar using the supplied sizing and actions.
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
      centerTitle: false,
      titleSpacing: AppSpacing.xl,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      title: AppProjectsBannerTitle(
        logoHeight: metrics.logoHeight,
        showTagline: metrics.showTagline,
      ),
      actions: actions,
    );
  }
}

/// Left-aligned logo for standard app bars on non-home routes.
class AppBrandTitleLogo extends StatelessWidget {
  /// Creates a title logo that fits within [maxWidth].
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
    final slotWidth = AppLayoutMetrics.of(context).isMobile
        ? height
        : AppBrandAssets.logoSlotWidth(
            availableWidth: maxWidth,
            height: height,
          );

    return SizedBox(
      width: slotWidth,
      height: height,
      child: AppBrandLogo(
        height: height,
        alignment: AlignmentDirectional.centerStart,
      ),
    );
  }
}

/// Layout metrics for [AppBrandTitle]: row vs stacked logo/label and the
/// toolbar height that fits the chosen arrangement.
@immutable
class AppBrandTitleMetrics {
  /// Describes the sizes and spacing for the chosen brand and title
  /// arrangement.
  const AppBrandTitleMetrics({
    required this.stacked,
    required this.toolbarHeight,
    required this.logoHeight,
    required this.brandTitleGap,
    required this.brandingPadding,
  });

  final bool stacked;
  final double toolbarHeight;
  final double logoHeight;
  final double brandTitleGap;
  final double brandingPadding;

  /// App-bar height that fits the logo in the default horizontal layout.
  static const double rowToolbarHeight = AppDesign.appBarBrandedHeight;

  /// Decides whether [label] fits beside the logo in [titleMaxWidth].
  ///
  /// Compact layouts keep the logo and label in one row to leave more room
  /// for the page content.
  factory AppBrandTitleMetrics.of(
    BuildContext context, {
    required String label,
    required double titleMaxWidth,
  }) {
    final layout = AppLayoutMetrics.of(context);
    final logoHeight = AppBrandAssets.heightFor(layout);
    final compact = layout.isMobile;
    final brandTitleGap = compact
        ? AppDesign.appBarBrandTitleGapCompact
        : AppDesign.appBarBrandTitleGap;
    final brandingPadding = compact
        ? AppDesign.appBarBrandingPaddingCompact
        : AppDesign.appBarBrandingPadding;
    final rowHeight = compact
        ? AppDesign.appBarBrandedHeightCompact
        : AppDesign.appBarBrandedHeight;

    final logoWidth = AppBrandAssets.logoSlotWidth(
      availableWidth: titleMaxWidth,
      height: logoHeight,
    );
    final labelMaxWidth = titleMaxWidth - logoWidth - brandTitleGap;

    final fitsBeside =
        labelMaxWidth > 0 &&
        !_labelExceedsWidth(
          context: context,
          label: label,
          maxWidth: labelMaxWidth,
          style: AppHeadings.h2(context),
        );

    // Compact chrome never stacks — a taller bar would defeat the purpose.
    if (fitsBeside || compact || layout.isDesktop) {
      return AppBrandTitleMetrics(
        stacked: false,
        toolbarHeight: rowHeight,
        logoHeight: logoHeight,
        brandTitleGap: brandTitleGap,
        brandingPadding: brandingPadding,
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
        brandingPadding * 2 +
        logoHeight +
        AppDesign.appBarBrandStackedGap +
        labelHeight;

    return AppBrandTitleMetrics(
      stacked: true,
      toolbarHeight: toolbarHeight,
      logoHeight: logoHeight,
      brandTitleGap: brandTitleGap,
      brandingPadding: brandingPadding,
    );
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

/// An app bar title with a brand mark and a page label.
///
/// In a stacked layout, the logo sits above the label so the label has the
/// full title width.
class AppBrandTitle extends StatelessWidget {
  /// Creates a banner title with brand artwork, [label], and an optional
  /// trailing widget.
  const AppBrandTitle({
    super.key,
    required this.label,
    required this.metrics,
    this.trailing,
  });

  final String label;
  final AppBrandTitleMetrics metrics;
  final Widget? trailing;

  /// The logo height selected by the title layout, in logical pixels.
  static double get logoHeight => AppDesign.appBarLogoHeight;

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
        final logoHeight = metrics.logoHeight;

        if (metrics.stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBrandTitleLogo(height: logoHeight, maxWidth: maxWidth),
              const SizedBox(height: AppDesign.appBarBrandStackedGap),
              _label(
                context,
                maxLines: AppDesign.appBarBrandLabelMaxLinesStacked,
              ),
            ],
          );
        }

        final logoWidth = AppLayoutMetrics.of(context).isMobile
            ? logoHeight
            : AppBrandAssets.logoSlotWidth(
                availableWidth: math.max(
                  logoHeight,
                  maxWidth -
                      metrics.brandTitleGap -
                      AppDesign.appBarMinimumTitleLabelWidth,
                ),
                height: logoHeight,
              );
        final labelMaxWidth = maxWidth - logoWidth - metrics.brandTitleGap;

        if (labelMaxWidth <= 0) {
          return AppBrandTitleLogo(height: logoHeight, maxWidth: maxWidth);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppBrandTitleLogo(height: logoHeight, maxWidth: logoWidth),
            SizedBox(width: metrics.brandTitleGap),
            Expanded(child: _label(context)),
          ],
        );
      },
    );
  }

  Widget _label(BuildContext context, {int maxLines = 1}) {
    final text = Text(
      label,
      style: AppLayoutMetrics.of(context).isMobile
          ? AppHeadings.h4(context)
          : AppHeadings.h2(context),
      maxLines: trailing == null ? maxLines : 1,
      overflow: TextOverflow.ellipsis,
    );
    if (trailing == null) {
      return text;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kMinInteractiveDimension + AppSpacing.md) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: trailing,
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            const SizedBox(width: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(
                  kMinInteractiveDimension,
                  constraints.maxWidth -
                      AppDesign.appBarMinimumTitleLabelWidth -
                      AppSpacing.md,
                ),
              ),
              child: trailing,
            ),
          ],
        );
      },
    );
  }
}
