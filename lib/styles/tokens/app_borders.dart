// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Border-width tokens for the app.
///
/// Used by input fields, outlined cards, dividers, and chart axes. Keep the
/// scale tight — adding a value here should be a deliberate design call.
class AppBorders {
  const AppBorders._();

  /// PDF table grid lines and other extra-fine separators.
  static const double hairline = 0.5;

  /// Default outlined-card / list-tile border thickness.
  static const double thin = 1.0;

  /// Slightly emphasized borders (default text-field, grouped panels).
  static const double regular = 1.5;

  /// Focus / active-state borders (e.g. focused text field).
  static const double focus = 2.0;
}
