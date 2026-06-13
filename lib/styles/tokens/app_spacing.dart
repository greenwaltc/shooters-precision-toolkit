// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/widgets.dart';

/// Spacing scale used throughout the app.
///
/// All padding, gap, and margin values should reference one of these tokens
/// instead of hardcoding numbers. The scale is intentionally small so that
/// touching one constant rebalances the entire UI.
///
/// Scale (in logical pixels):
///   * [xs]  =  2
///   * [sm]  =  4
///   * [md]  =  8
///   * [lg]  = 12
///   * [xl]  = 16
///   * [xxl] = 20
///   * [xxxl] = 24
///   * [xxxxl] = 32
class AppSpacing {
  const AppSpacing._();

  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double xxxxl = 32;

  // Common composed insets.

  /// Page-level padding around scaffold body content.
  static const EdgeInsets page = EdgeInsets.all(xl);

  /// Padding inside outlined surface cards (header summary etc.).
  static const EdgeInsets cardPadding = EdgeInsets.all(xxl);

  /// Standard padding inside form text fields and grouped panels.
  static const EdgeInsets fieldPadding = EdgeInsets.all(md);

  /// Padding for grouped form sections (factor blocks).
  static const EdgeInsets groupedPanel = EdgeInsets.all(lg);

  /// Padding for the empty / placeholder result state.
  static const EdgeInsets emptyState = EdgeInsets.all(xxxxl);

  /// Title above a grouped factor block.
  static const EdgeInsets factorTitle = EdgeInsets.fromLTRB(md, 0, md, sm);

  /// Title above a form section.
  static const EdgeInsets formSectionTitle = EdgeInsets.fromLTRB(
    md,
    xxl,
    md,
    md,
  );

  /// Vertical padding for items inside a radio list group.
  static const EdgeInsets radioItemVertical = EdgeInsets.symmetric(
    vertical: sm,
  );

  /// Vertical padding for table cells in the form's detection table.
  static const EdgeInsets tableCellVertical = EdgeInsets.symmetric(
    vertical: xs,
  );

  /// Padding inside the cell renderer of the Pluto factor columns.
  static const EdgeInsets plutoFactorCell = EdgeInsets.symmetric(
    horizontal: lg,
  );
}
