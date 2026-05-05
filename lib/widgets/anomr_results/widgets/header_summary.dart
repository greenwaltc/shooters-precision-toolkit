import 'package:flutter/material.dart';

import '../../../model/project_form_model.dart';
import 'stat_tile.dart';

/// Summary card displayed at the top of the results page: title, sample-size
/// description, and a row (or column on narrow viewports) of stat tiles.
class HeaderSummary extends StatelessWidget {
  const HeaderSummary({
    super.key,
    required this.grandMean,
    required this.riskLevel,
    required this.detectableDiffPercent,
    required this.sampleSizeLabel,
  });

  final double grandMean;
  final RiskLevel riskLevel;
  final double detectableDiffPercent;
  final String sampleSizeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis of Mean Ranges',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(sampleSizeLabel, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stats = [
                  StatTile(
                    label: 'Grand Mean',
                    value: grandMean.toStringAsFixed(4),
                  ),
                  StatTile(label: 'Risk Level', value: riskLevel.label),
                  StatTile(
                    label: 'Detectable Difference',
                    value:
                        '±${(detectableDiffPercent * 100).toStringAsFixed(0)}%',
                  ),
                ];
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final stat in stats) ...[
                        stat,
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stats,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
