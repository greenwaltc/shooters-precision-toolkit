// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/chart/chart_scale.dart';
import '../../../styles/tokens/app_spacing.dart';
import '../models/factor_row.dart';
import 'conclusion_row.dart';

/// Stacked list of [ConclusionRow]s, one per factor, under a section title.
class ConclusionList extends StatelessWidget {
  const ConclusionList({
    super.key,
    required this.factorRows,
    required this.riskLevel,
    required this.scale,
  });

  final List<FactorRow> factorRows;
  final RiskLevel riskLevel;
  final ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per-factor results at risk level ${riskLevel.label}',
          style: textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: scale.axisLabelFontSize + 1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < factorRows.length; i++) ...[
          ConclusionRow(row: factorRows[i], scale: scale),
          if (i != factorRows.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
