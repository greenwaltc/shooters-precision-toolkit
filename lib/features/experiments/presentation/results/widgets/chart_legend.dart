import 'package:flutter/material.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/chart/chart_scale.dart';
import '../models/factor_row.dart';
import 'legend_chip.dart';
import 'legend_painter.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Wrap of legend chips: one per factor, plus the shared grand-mean and
/// risk-bound entries.
class ChartLegend extends StatelessWidget {
  /// Creates a chart key for factor colors and statistical reference lines.
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
                    ? context.l10n.factorLegend(row.index + 1, row.displayName)
                    : row.displayName,
                color: row.color,
                style: LegendStyle.solidDots,
                scale: scale,
                onSurfaceVariant: scheme.onSurfaceVariant,
                maxWidth: maxChipWidth,
              ),
            LegendChip(
              label: context.l10n.grandMeanMessage,
              color: grandMeanColor,
              style: LegendStyle.solid,
              scale: scale,
              onSurfaceVariant: scheme.onSurfaceVariant,
              maxWidth: maxChipWidth,
            ),
            LegendChip(
              label: context.l10n.riskBounds,
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
