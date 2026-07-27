// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/components/outlined_surface_card.dart';
import '../../../styles/components/stat_tile.dart';
import '../../../styles/layout/app_layout.dart';
import '../../../styles/tokens/app_spacing.dart';
import '../../../styles/tokens/app_text_styles.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return OutlinedSurfaceCard(
      variant: OutlinedSurfaceVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Parameters',
            style: AppTextStyles.headerSummaryTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(sampleSizeLabel, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppLayoutMetrics(
                width: constraints.maxWidth,
                height: MediaQuery.sizeOf(context).height,
              );
              final stats = [
                StatTile(
                  label: 'Grand Mean',
                  value: grandMean.toStringAsFixed(4),
                ),
                StatTile(label: 'Risk Level', value: riskLevel.label),
                StatTile(
                  label: 'Detectable Difference',
                  value: SampleSizeOption.formatFraction(detectableDiffPercent),
                ),
              ];
              if (layout.useStackedActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final stat in stats) ...[
                      stat,
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < stats.length; index++) ...[
                    Flexible(child: stats[index]),
                    if (index != stats.length - 1)
                      const SizedBox(width: AppSpacing.lg),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
