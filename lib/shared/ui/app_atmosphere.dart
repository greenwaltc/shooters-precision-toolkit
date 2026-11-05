// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import 'product_configuration.dart';
import 'theme/app_design.dart';

/// Full-bleed photographic atmosphere painted behind every route.
///
/// Intended to sit above a solid [ColorScheme.surface] fill and under a
/// transparent [Scaffold] / app bar so the image shows through chrome without
/// changing page layout.
class AppAtmosphere extends StatelessWidget {
  /// Creates the app's decorative background artwork.
  const AppAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    final asset = BrandConfiguration.defaults.atmosphereAsset;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox.expand(
          child: Opacity(
            opacity: AppDesign.atmosphereOpacity,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
