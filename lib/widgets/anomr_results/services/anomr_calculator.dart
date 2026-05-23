// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/chart/chart_layout.dart';
import '../../../styles/tokens/app_colors.dart';
import '../models/anomr_summary.dart';
import '../models/effect_status.dart';
import '../models/factor_row.dart';
import '../models/factor_stats.dart';

/// Pure (no `BuildContext`) computations used to derive the values the
/// results view renders.
class AnomrCalculator {
  const AnomrCalculator._();

  static double mean(List<double> values) {
    if (values.isEmpty) return double.nan;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static List<double> collectRanges(PlutoGridStateManager manager) {
    return manager.rows
        .map(
          (row) => double.tryParse(row.cells['range']?.value?.toString() ?? ''),
        )
        .whereType<double>()
        .toList(growable: false);
  }

  static FactorStats statsFor({
    required PlutoGridStateManager manager,
    required String factorField,
    required String firstState,
    required String secondState,
  }) {
    final firstRanges = <double>[];
    final secondRanges = <double>[];

    for (final row in manager.rows) {
      final rangeValue = double.tryParse(
        row.cells['range']?.value?.toString() ?? '',
      );
      if (rangeValue == null) continue;

      final factorValue = row.cells[factorField]?.value?.toString();
      if (factorValue == firstState) {
        firstRanges.add(rangeValue);
      } else if (factorValue == secondState) {
        secondRanges.add(rangeValue);
      }
    }

    return FactorStats(
      firstMean: mean(firstRanges),
      secondMean: mean(secondRanges),
      firstCount: firstRanges.length,
      secondCount: secondRanges.length,
    );
  }

  static String factorDisplayName(FactorDefinition factor, int index) {
    return factor.name.trim().isEmpty ? 'Factor ${index + 1}' : factor.name;
  }

  static String stateDisplayName(String state, int fallbackIndex) {
    return state.trim().isEmpty ? '$fallbackIndex' : state;
  }

  static EffectStatus computeStatus({
    required FactorStats stats,
    required double lowerBound,
    required double upperBound,
  }) {
    if (!stats.hasBoth) return EffectStatus.insufficient;

    final firstOutside =
        stats.firstMean > upperBound || stats.firstMean < lowerBound;
    final secondOutside =
        stats.secondMean > upperBound || stats.secondMean < lowerBound;

    if (firstOutside && secondOutside) return EffectStatus.significant;
    if (!firstOutside && !secondOutside) return EffectStatus.notDetected;
    return EffectStatus.marginal;
  }

  static List<FactorRow> buildFactorRows({
    required List<FactorDefinition> factors,
    required PlutoGridStateManager manager,
    required double lowerBound,
    required double upperBound,
    ChartLayoutGeometry layout = ChartLayout.standard,
  }) {
    return List.generate(factors.length, (i) {
      final factor = factors[i];
      final firstLabel = stateDisplayName(factor.firstState, 1);
      final secondLabel = stateDisplayName(factor.secondState, 2);
      final stats = statsFor(
        manager: manager,
        factorField: 'factor_$i',
        firstState: firstLabel,
        secondState: secondLabel,
      );
      return FactorRow(
        index: i,
        factor: factor,
        stats: stats,
        color: AppColors.factorColor(i),
        status: computeStatus(
          stats: stats,
          lowerBound: lowerBound,
          upperBound: upperBound,
        ),
        firstX: layout.firstXFor(i),
        secondX: layout.secondXFor(i),
        firstLabel: firstLabel,
        secondLabel: secondLabel,
        displayName: factorDisplayName(factor, i),
      );
    });
  }

  /// Builds a complete [AnomrSummary] from a [ProjectFormModel] +
  /// [PlutoGridStateManager] pair.
  static AnomrSummary summarize({
    required ProjectFormModel formModel,
    required PlutoGridStateManager stateManager,
    ChartLayoutGeometry layout = ChartLayout.standard,
  }) {
    final ranges = collectRanges(stateManager);
    final grandMean = mean(ranges);
    final detectableDiffPercent = formModel.sampleSizeOption
        .detectableDifferenceFor(formModel.riskLevel);
    final upperBound = grandMean * (1 + detectableDiffPercent);
    final lowerBound = grandMean * (1 - detectableDiffPercent);
    final factorRows = buildFactorRows(
      factors: formModel.factorDefinitions,
      manager: stateManager,
      lowerBound: lowerBound,
      upperBound: upperBound,
      layout: layout,
    );

    return AnomrSummary(
      ranges: ranges,
      grandMean: grandMean,
      detectableDiffPercent: detectableDiffPercent,
      lowerBound: lowerBound,
      upperBound: upperBound,
      factorRows: factorRows,
    );
  }
}
