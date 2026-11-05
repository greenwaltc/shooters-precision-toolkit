// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Styling constants for the ANOMR matrix Pluto grid.
class MatrixGridStyle {
  const MatrixGridStyle._();

  /// Minimum width for read-only index columns before autofit runs.
  static const double indexColumnMinWidth = 52;

  /// Default factor column width.
  static const double factorColumnWidth = 120;

  /// Default range column width.
  static const double rangeColumnWidth = 150;

  /// Matches [PlutoGridSettings.rowBorderWidth] without importing Pluto here.
  static const double rowBorderWidth = 1;
}
