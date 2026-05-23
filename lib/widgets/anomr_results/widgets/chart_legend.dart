// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/chart/chart_scale.dart';
import '../models/factor_row.dart';
import 'legend_chip.dart';
import 'legend_painter.dart';

/// Wrap of legend chips: one per factor, plus the shared grand-mean and
/// risk-bound entries.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.factorRows,
    required this.scale,
    required this.grandMeanColor,
    required this.boundColor,
  });

  final List<FactorRow> factorRows;
  final ChartScale scale;
  final Color grandMeanColor;
  final Color boundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = scale.isCompact
            ? constraints.maxWidth
            : constraints.maxWidth / 2;

        return Wrap(
          spacing: scale.legendItemSpacing,
          runSpacing: scale.legendRunSpacing,
          children: [
            for (final row in factorRows)
              LegendChip(
                label: scale.isCompact
                    ? 'F${row.index + 1}: ${row.displayName}'
                    : row.displayName,
                color: row.color,
                style: LegendStyle.solidDots,
                scale: scale,
                onSurfaceVariant: scheme.onSurfaceVariant,
                maxWidth: maxChipWidth,
              ),
            LegendChip(
              label: 'Grand mean',
              color: grandMeanColor,
              style: LegendStyle.solid,
              scale: scale,
              onSurfaceVariant: scheme.onSurfaceVariant,
              maxWidth: maxChipWidth,
            ),
            LegendChip(
              label: 'Risk bounds',
              color: boundColor,
              style: LegendStyle.dashed,
              scale: scale,
              onSurfaceVariant: scheme.onSurfaceVariant,
              maxWidth: maxChipWidth,
            ),
          ],
        );
      },
    );
  }
}
