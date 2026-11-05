// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Aggregate statistics for one factor's two states, computed from the
/// "range" column of the ANOMR matrix.
class FactorStats {
  /// Creates statistics from two state means and their sample counts.
  ///
  /// Use a count of zero when a state has no measurements.
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

  /// Whether the first state has any measurements.
  bool get hasFirst => firstCount > 0;

  /// Whether the second state has any measurements.
  bool get hasSecond => secondCount > 0;

  /// Whether both states have enough data to compute a mean.
  bool get hasBoth => hasFirst && hasSecond;
}
