import 'package:flutter/material.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/components/outlined_surface_card.dart';
import '../../../../../shared/ui/theme/components/stat_tile.dart';
import '../../../../../shared/ui/theme/layout/app_layout.dart';
import '../../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../../../../../shared/ui/theme/tokens/app_text_styles.dart';
import '../../test_design/project_form_model.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

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

    if (AppLayoutMetrics.of(context).isMobile) {
      final parameters = <String, String>{
        context.l10n.grandMeanMessage: context.decimal(grandMean),
        context.l10n.riskLevelMessage: riskLevel.label,
        context.l10n.detectableDifference: SampleSizeLabels.formatFraction(
          detectableDiffPercent,
        ),
      };
      return OutlinedSurfaceCard(
        variant: OutlinedSurfaceVariant.tinted,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.projectParameters, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(sampleSizeLabel, style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            for (final entry in parameters.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key, style: textTheme.bodyMedium),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Text(entry.value, style: textTheme.titleMedium),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    if (MediaQuery.sizeOf(context).width >=
        AppLayoutMetrics.desktopBreakpoint) {
      return OutlinedSurfaceCard(
        variant: OutlinedSurfaceVariant.tinted,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.projectParameters,
                    style: AppTextStyles.headerSummaryTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(sampleSizeLabel, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              flex: 6,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StatTile(
                      label: context.l10n.grandMean,
                      value: context.decimal(grandMean),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: StatTile(
                      label: context.l10n.riskLevel,
                      value: riskLevel.label,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: StatTile(
                      label: context.l10n.detectableDifferenceMessage,
                      value: SampleSizeLabels.formatFraction(
                        detectableDiffPercent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return OutlinedSurfaceCard(
      variant: OutlinedSurfaceVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.projectParameters,
            style: AppTextStyles.headerSummaryTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(sampleSizeLabel, style: textTheme.bodyMedium),
          SizedBox(
            height: MediaQuery.sizeOf(context).width >= 1024
                ? 8
                : AppSpacing.xl,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppLayoutMetrics(
                width: constraints.maxWidth,
                height: MediaQuery.sizeOf(context).height,
              );
              final stats = [
                StatTile(
                  label: context.l10n.grandMean,
                  value: context.decimal(grandMean),
                ),
                StatTile(label: context.l10n.riskLevel, value: riskLevel.label),
                StatTile(
                  label: context.l10n.detectableDifferenceMessage,
                  value: SampleSizeLabels.formatFraction(detectableDiffPercent),
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
