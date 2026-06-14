// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import '../app_design.dart';

/// Border-width tokens for the app — a typed facet over [AppDesign].
///
/// Used by input fields, outlined cards, dividers, and chart axes. The raw
/// values live in [AppDesign]; keep the scale tight.
class AppBorders {
  const AppBorders._();

  /// PDF table grid lines and other extra-fine separators.
  static const double hairline = AppDesign.borderHairline;

  /// Default outlined-card / list-tile border thickness.
  static const double thin = AppDesign.borderThin;

  /// Slightly emphasized borders (default text-field, grouped panels).
  static const double regular = AppDesign.borderRegular;

  /// Focus / active-state borders (e.g. focused text field).
  static const double focus = AppDesign.borderFocus;
}
