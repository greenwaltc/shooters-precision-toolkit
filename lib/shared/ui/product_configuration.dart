import 'package:flutter/widgets.dart';

import '../foundation/feature_flags.dart';
import '../l10n/app_copy.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

export '../foundation/feature_flags.dart' show FeatureFlag, FeatureFlags;

/// Product identity surfaced in app chrome: window title, logo art, tagline,
/// and the copyright line.
///
/// Kept out of widget code so rebranding (or white-labelling a build) is a
/// single-file change. Sizing of the branding lives in `AppDesign` instead;
/// this holds only the content and the assets it points at.
class BrandConfiguration {
  const BrandConfiguration({
    required this.bannerLogoAsset,
    required this.compactLogoAsset,
    required this.bannerLogoAspectRatio,
    required this.atmosphereAsset,
  });

  static const BrandConfiguration defaults = BrandConfiguration(
    bannerLogoAsset: 'assets/projects_banner_logo.png',
    compactLogoAsset: 'assets/icon/app_icon_compact.png',
    bannerLogoAspectRatio: 1801 / 504,
    atmosphereAsset: 'assets/img/target_bg.png',
  );

  /// Product name used for the OS window/task title and as the logo alt text.
  String get appTitle => AppCopy.english.bramwellSPrecisionTestKit;

  /// Descriptor shown beneath the logo on the projects banner.
  String get tagline =>
      AppCopy.english.theModernToolForComparingProjectileConsistency;

  /// Footer notice rendered at the bottom of every page.
  String get copyrightNotice => AppCopy.english.copyrightCredit;

  /// Wide wordmark used wherever the full banner fits.
  final String bannerLogoAsset;

  /// Square mark substituted when the banner would be clipped.
  final String compactLogoAsset;

  /// Intrinsic width/height of [bannerLogoAsset]. Used to predict the width
  /// the banner needs at a given height before it is laid out.
  final double bannerLogoAspectRatio;

  /// Soft photographic atmosphere painted behind every page (under transparent
  /// scaffolds and app bars).
  final String atmosphereAsset;

  /// Canonical public origin for the Firebase Hosting web build (no trailing
  /// slash). Used by `web/sitemap.xml` / `web/robots.txt` and any absolute
  /// links identifying the public product. Runtime Auth return URLs use the
  /// validated origin of the active deployment profile.
  ///
  /// Keep `config/web_environments.json` and the static files under `web/` in
  /// sync when this value changes.
  static const String publicSiteUrl = 'https://bramwelltest.com';
}

/// User-facing chrome copy that is not part of the product brand itself.
///
/// Kept here (rather than scattered string literals) so labels stay consistent
/// across every entry point that shares the same action.
class UiCopyConfiguration {
  const UiCopyConfiguration();

  static const UiCopyConfiguration defaults = UiCopyConfiguration();

  /// Primary CTA used to start a new project from the Projects home page.
  String get createProjectLabel => AppCopy.english.createANewProject;
}

/// Application-wide configuration for project behavior.
class ProjectConfiguration {
  const ProjectConfiguration({
    required this.featureFlags,
    required this.brand,
    required this.uiCopy,
  });

  /// Active configuration for the running app.
  static const ProjectConfiguration defaults = ProjectConfiguration(
    featureFlags: FeatureFlags.defaults,
    brand: BrandConfiguration.defaults,
    uiCopy: UiCopyConfiguration.defaults,
  );

  final FeatureFlags featureFlags;
  final BrandConfiguration brand;
  final UiCopyConfiguration uiCopy;
}

/// UI-only distribution of immutable product policy. Core logic receives values.
class ProjectConfigurationScope extends InheritedWidget {
  const ProjectConfigurationScope({
    super.key,
    required this.configuration,
    required super.child,
  });
  final ProjectConfiguration configuration;
  static ProjectConfiguration of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ProjectConfigurationScope>();
    if (scope == null) {
      throw StateError('Missing product configuration scope.');
    }
    return scope.configuration;
  }

  @override
  bool updateShouldNotify(ProjectConfigurationScope oldWidget) =>
      configuration != oldWidget.configuration;
}
