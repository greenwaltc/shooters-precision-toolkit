// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Per-factor outcome of comparing the two state means against the
/// detectable-difference bounds derived from the project risk level.
enum EffectStatus {
  significant('Detectable difference'),
  notDetected('No detectable difference'),
  marginal('Marginal'),
  insufficient('Insufficient data');

  const EffectStatus(this.label);

  final String label;
}
