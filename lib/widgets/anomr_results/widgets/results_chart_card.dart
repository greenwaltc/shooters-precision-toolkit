import 'package:flutter/material.dart';

import '../../../model/project_form_model.dart';
import '../models/factor_row.dart';
import '../theme/chart_scale.dart';
import 'chart_legend.dart';
import 'combined_line_chart.dart';
import 'conclusion_list.dart';

/// Card surface that wraps the chart, legend, and per-factor conclusion
/// list. Designed to be captured as a single image during export.
class ResultsChartCard extends StatelessWidget {
  const ResultsChartCard({
    super.key,
    required this.factorRows,
    required this.grandMean,
    required this.lowerBound,
    required this.upperBound,
    required this.detectableDiffPercent,
    required this.riskLevel,
    required this.scale,
  });

  final List<FactorRow> factorRows;
  final double grandMean;
  final double lowerBound;
  final double upperBound;
  final double detectableDiffPercent;
  final RiskLevel riskLevel;
  final ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(scale.chartOuterPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(scale: scale, textTheme: textTheme, scheme: scheme),
            SizedBox(height: scale.chartOuterPadding),
            SizedBox(
              height: scale.chartHeight,
              child: CombinedLineChart(
                factorRows: factorRows,
                grandMean: grandMean,
                lowerBound: lowerBound,
                upperBound: upperBound,
                detectableDiffPercent: detectableDiffPercent,
                scale: scale,
              ),
            ),
            SizedBox(height: scale.chartOuterPadding),
            ChartLegend(
              factorRows: factorRows,
              scale: scale,
              grandMeanColor: scheme.onSurface.withValues(alpha: 0.6),
              boundColor: scheme.error,
            ),
            SizedBox(height: scale.chartOuterPadding),
            ConclusionList(
              factorRows: factorRows,
              riskLevel: riskLevel,
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.scale,
    required this.textTheme,
    required this.scheme,
  });

  final ChartScale scale;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (textTheme.titleLarge?.fontSize ?? 22) *
                scale.scale.clamp(0.9, 1.2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mean ranges per factor state vs. grand mean',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
