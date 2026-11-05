// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/foundation.dart';
import 'package:pluto_grid/pluto_grid.dart';

/// Immutable row payload used to initialize the ANOMR matrix grid.
@immutable
class MatrixGridData {
  /// Copies the row list into read-only order while retaining the original cell
  /// objects.
  MatrixGridData({required List<PlutoRow> rows, required this.totalSamples})
    : rows = List.unmodifiable(rows);

  /// Read-only row ordering; each PlutoRow remains an SDK-owned mutable cell set.
  /// The grid takes a mutable copy of this list when initializing its viewport.
  final List<PlutoRow> rows;

  /// Total range rows expected for the selected sample-size option.
  final int totalSamples;
}
