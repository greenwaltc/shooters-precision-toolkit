// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Stable string keys for feature flags (suitable for JSON / remote config).
enum FeatureFlag {
  imputeMissingData('impute_missing_data'),
  themeModeToggle('theme_mode_toggle');

  const FeatureFlag(this.key);

  final String key;
}

/// Typed feature-flag registry with compile-time defaults.
///
/// Follows the common pattern of named flags, explicit defaults, and a single
/// lookup API so overrides (environment, remote config, etc.) can be added
/// later without changing call sites.
class FeatureFlags {
  const FeatureFlags({required Map<FeatureFlag, bool> values})
    : _values = values;

  static const FeatureFlags defaults = FeatureFlags(
    values: {
      FeatureFlag.imputeMissingData: false,
      FeatureFlag.themeModeToggle: false,
    },
  );

  final Map<FeatureFlag, bool> _values;

  bool isEnabled(FeatureFlag flag) => _values[flag] ?? false;
}

/// Product identity surfaced in app chrome: window title, logo art, tagline,
/// and the copyright line.
///
/// Kept out of widget code so rebranding (or white-labelling a build) is a
/// single-file change. Sizing of the branding lives in `AppDesign` instead;
/// this holds only the content and the assets it points at.
class BrandConfiguration {
  const BrandConfiguration({
    required this.appTitle,
    required this.tagline,
    required this.copyrightNotice,
    required this.bannerLogoAsset,
    required this.compactLogoAsset,
    required this.bannerLogoAspectRatio,
  });

  static const BrandConfiguration defaults = BrandConfiguration(
    appTitle: "Bramwell's Precision Test Kit",
    tagline: 'The modern tool for comparing projectile consistency',
    copyrightNotice: '\u00A9 2026 Denton M. Bramwell. All rights reserved.',
    bannerLogoAsset: 'assets/projects_banner_logo.png',
    compactLogoAsset: 'assets/icon/app_icon.png',
    bannerLogoAspectRatio: 1801 / 504,
  );

  /// Product name used for the OS window/task title and as the logo alt text.
  final String appTitle;

  /// Single-line descriptor shown beneath the logo on the projects banner.
  final String tagline;

  /// Footer notice rendered at the bottom of every page.
  final String copyrightNotice;

  /// Wide wordmark used wherever the full banner fits.
  final String bannerLogoAsset;

  /// Square mark substituted when the banner would be clipped.
  final String compactLogoAsset;

  /// Intrinsic width/height of [bannerLogoAsset]. Used to predict the width
  /// the banner needs at a given height before it is laid out.
  final double bannerLogoAspectRatio;

  /// Canonical public origin for the Firebase Hosting web build (no trailing
  /// slash). Used by `web/sitemap.xml` / `web/robots.txt` and any absolute
  /// links that must match the live site.
  ///
  /// Keep the static files under `web/` in sync when this value changes.
  static const String publicSiteUrl =
      'https://bramwells-precision-test-kit.web.app';
}

/// User-facing chrome copy that is not part of the product brand itself.
///
/// Kept here (rather than scattered string literals) so labels stay consistent
/// across home, drawer, and any other entry points that share the same action.
class UiCopyConfiguration {
  const UiCopyConfiguration({required this.createProjectLabel});

  static const UiCopyConfiguration defaults = UiCopyConfiguration(
    createProjectLabel: 'Create a New Project',
  );

  /// Primary CTA used to start a new project from home and the drawer.
  final String createProjectLabel;
}

/// Application-wide configuration for project behavior.
class ProjectConfiguration {
  const ProjectConfiguration({
    required this.featureFlags,
    required this.brand,
    required this.uiCopy,
  });

  /// Active configuration for the running app.
  static const ProjectConfiguration current = ProjectConfiguration(
    featureFlags: FeatureFlags.defaults,
    brand: BrandConfiguration.defaults,
    uiCopy: UiCopyConfiguration.defaults,
  );

  final FeatureFlags featureFlags;
  final BrandConfiguration brand;
  final UiCopyConfiguration uiCopy;
}
