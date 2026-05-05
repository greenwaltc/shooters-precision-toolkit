// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/foundation.dart';

/// Aggregate statistics for one factor's two states, computed from the
/// "range" column of the ANOMR matrix.
@immutable
class FactorStats {
  const FactorStats({
    required this.firstMean,
    required this.secondMean,
    required this.firstCount,
    required this.secondCount,
  });

  final double firstMean;
  final double secondMean;
  final int firstCount;
  final int secondCount;

  bool get hasFirst => firstCount > 0;
  bool get hasSecond => secondCount > 0;
  bool get hasBoth => hasFirst && hasSecond;
}
