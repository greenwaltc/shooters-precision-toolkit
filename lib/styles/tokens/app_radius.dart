// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/widgets.dart';

import '../app_design.dart';

/// Border-radius tokens for the app — a typed facet over [AppDesign].
///
/// Each token is exposed both as a raw `double` (for use as a single
/// [Radius] value) and as a pre-built [BorderRadius]. Use the
/// [BorderRadius] form whenever possible — it keeps widget code free of
/// `BorderRadius.circular(...)` literals. The raw values live in [AppDesign].
class AppRadius {
  const AppRadius._();

  /// Compact radius used for project list cards in the home page.
  static const double sm = AppDesign.radiusSm;

  /// Bottom-sheet radius.
  static const double bottomSheet = AppDesign.radiusBottomSheet;

  /// Default form-field / grouped-panel / button radius.
  static const double md = AppDesign.radiusMd;

  /// Outlined surface card radius.
  static const double lg = AppDesign.radiusLg;

  /// Large dialog / hero card radius (results card, export dialog).
  static const double xl = AppDesign.radiusXl;

  /// Full pill radius used by status pills.
  static const double pill = AppDesign.radiusPill;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius bottomSheetRadius = BorderRadius.all(
    Radius.circular(bottomSheet),
  );
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
