// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/foundation.dart';
import 'package:pluto_grid/pluto_grid.dart';

/// Immutable row payload used to initialize the ANOMR matrix grid.
@immutable
class MatrixGridData {
  const MatrixGridData({required this.rows, required this.totalSamples});

  /// Pluto rows rendered by the matrix.
  final List<PlutoRow> rows;

  /// Total range rows expected for the selected sample-size option.
  final int totalSamples;
}
