// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Placeholder examples shown for a single factor definition row.
class FactorFieldHints {
  const FactorFieldHints({
    required this.factorName,
    required this.firstState,
    required this.secondState,
  });

  /// Example factor name.
  final String factorName;

  /// Example label for the first factor state.
  final String firstState;

  /// Example label for the second factor state.
  final String secondState;
}

/// Stable example hints for the maximum supported factor count.
const factorFieldHintsByIndex = <FactorFieldHints>[
  FactorFieldHints(
    factorName: 'Bullet Point Type',
    firstState: 'Rounded',
    secondState: 'Pointy',
  ),
  FactorFieldHints(
    factorName: 'Primer',
    firstState: 'Magnum',
    secondState: 'Regular',
  ),
  FactorFieldHints(
    factorName: 'Powder Charge',
    firstState: 'Full',
    secondState: '75%',
  ),
  FactorFieldHints(
    factorName: 'Shooting Position',
    firstState: 'Kneeling',
    secondState: 'Prone',
  ),
];
