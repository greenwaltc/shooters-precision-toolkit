// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Opacity / alpha tokens for layered surfaces and tinted highlights.
///
/// These are deliberately a small set — most colors should come from
/// [ColorScheme] without further opacity adjustment. Use these tokens only
/// where a layered tint is part of the design (status pills, conclusion
/// rows, chart grid lines, etc.).
class AppOpacity {
  const AppOpacity._();

  /// Background tint for the header summary card on top of
  /// `surfaceContainerHighest`.
  static const double cardTint = 0.4;

  /// Tint applied to a factor color when used as a row background fill.
  static const double rowFill = 0.05;

  /// Tint applied to a factor color when used as a row border.
  static const double rowBorder = 0.35;

  /// Tint applied to a status color when used as a status-pill fill.
  static const double pillFill = 0.10;

  /// Tint applied to a status color when used as a status-pill border.
  static const double pillBorder = 0.40;

  /// Subtle horizontal grid lines on the chart.
  static const double chartGridLine = 0.6;

  /// Grand-mean and other "neutral" reference colors derived from
  /// `onSurface`.
  static const double neutralReference = 0.6;

  /// Fade applied to disabled / non-applicable controls in dialogs.
  static const double disabled = 0.5;
}
