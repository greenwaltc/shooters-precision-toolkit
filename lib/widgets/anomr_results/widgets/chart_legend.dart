import 'package:flutter/material.dart';

import '../models/factor_row.dart';
import '../theme/chart_scale.dart';
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

    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        for (final row in factorRows)
          LegendChip(
            label: row.displayName,
            color: row.color,
            style: LegendStyle.solidDots,
            scale: scale,
            onSurfaceVariant: scheme.onSurfaceVariant,
          ),
        LegendChip(
          label: 'Grand mean',
          color: grandMeanColor,
          style: LegendStyle.solid,
          scale: scale,
          onSurfaceVariant: scheme.onSurfaceVariant,
        ),
        LegendChip(
          label: 'Risk bounds',
          color: boundColor,
          style: LegendStyle.dashed,
          scale: scale,
          onSurfaceVariant: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
