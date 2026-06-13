// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/chart/chart_scale.dart';
import '../../../styles/components/outlined_surface_card.dart';
import '../../../styles/theme_extensions/anomr_chart_theme.dart';
import '../../../styles/tokens/app_radius.dart';
import '../../../styles/tokens/app_spacing.dart';
import '../models/factor_row.dart';
import 'chart_legend.dart';
import 'combined_line_chart.dart';
import 'conclusion_list.dart';

/// Card surface that wraps the chart, legend, and per-factor conclusion list.
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
    final chartTheme =
        Theme.of(context).extension<AnomrChartTheme>() ??
        const AnomrChartTheme.standard();

    return OutlinedSurfaceCard(
      borderRadius: AppRadius.xlRadius,
      padding: EdgeInsets.all(scale.chartOuterPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title(scale: scale),
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
            grandMeanColor: scheme.onSurface.withValues(
              alpha: chartTheme.referenceLineOpacity,
            ),
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
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.scale});

  final ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize:
                (textTheme.titleLarge?.fontSize ?? 22) *
                scale.scale.clamp(0.9, 1.2),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Mean ranges per factor state vs. grand mean',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
