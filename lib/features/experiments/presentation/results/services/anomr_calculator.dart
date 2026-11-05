import 'package:pluto_grid/pluto_grid.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/chart/chart_layout.dart';
import '../../../../../shared/ui/theme/tokens/app_colors.dart';
import '../../../api/factor_stats.dart';
import '../../../domain/precision_calculator.dart';
import '../../../domain/range_value_parser.dart';
import '../../test_design/project_form_model.dart';
import '../models/anomr_summary.dart';
import '../models/effect_status.dart';
import '../models/factor_row.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Presentation adapter: snapshots grid cells, delegates numeric rules to the
/// pure calculator, then assigns chart labels, colors and coordinates.
class AnomrCalculator {
  const AnomrCalculator._();

  static List<MatrixObservation> _observations(
    PlutoGridStateManager manager,
  ) => [
    for (final row in manager.rows)
      MatrixObservation(
        factorStates: [
          for (
            var index = 0;
            index <
                row.cells.keys.where((key) => key.startsWith('factor_')).length;
            index++
          )
            row.cells['factor_$index']?.value?.toString() ?? '',
        ],
        groupSize: RangeValueParser.toDouble(row.cells['range']?.value),
      ),
  ];

  /// Returns the mean of finite [values], or NaN for an empty list.
  ///
  /// Throws [ArgumentError] for nonfinite values.
  static double mean(List<double> values) => PrecisionCalculator.mean(values);

  /// Reads usable measurements from the grid in row order.
  ///
  /// With [imputeMissingData] enabled, substitutes the observed mean for
  /// missing values when possible.
  static List<double> collectRanges(
    PlutoGridStateManager manager, {
    bool imputeMissingData = false,
  }) => PrecisionCalculator.collectRanges(
    _observations(manager),
    imputeMissingData: imputeMissingData,
  );

  /// Checks for an empty grid or any row without a usable measurement.
  static bool hasMissingRangeData(PlutoGridStateManager manager) =>
      manager.rows.isEmpty ||
      _observations(manager).any((row) => row.groupSize == null);

  /// Calculates means and counts for the two named states in [factorField].
  ///
  /// Use a grid field of the form `factor_N`, where N is its zero-based index.
  /// Missing measurements can use [imputeWith].
  static FactorStats statsFor({
    required PlutoGridStateManager manager,
    required String factorField,
    required String firstState,
    required String secondState,
    double? imputeWith,
  }) => PrecisionCalculator.statsFor(
    rows: _observations(manager),
    factorIndex: int.parse(factorField.substring('factor_'.length)),
    firstState: firstState,
    secondState: secondState,
    imputeWith: imputeWith,
  );

  /// Uses the factor name or a numbered fallback based on its zero-based
  /// [index].
  static String factorDisplayName(FactorDefinition factor, int index) {
    return factor.name.trim().isEmpty
        ? AppCopy.english.factorNumber(index + 1)
        : factor.name;
  }

  /// Uses [state] as the label or [fallbackIndex] as text when the name is
  /// blank.
  static String stateDisplayName(String state, int fallbackIndex) {
    return state.trim().isEmpty ? '$fallbackIndex' : state;
  }

  /// Classifies the state means against the inclusive risk bounds.
  static EffectStatus computeStatus({
    required FactorStats stats,
    required double lowerBound,
    required double upperBound,
  }) => PrecisionCalculator.computeStatus(
    stats: stats,
    lowerBound: lowerBound,
    upperBound: upperBound,
  );

  /// Builds chart rows in [factors] order with positions from [layout].
  ///
  /// Each row includes statistics, status, labels, and a color.
  static List<FactorRow> buildFactorRows({
    required List<FactorDefinition> factors,
    required PlutoGridStateManager manager,
    required double lowerBound,
    required double upperBound,
    double? imputeWith,
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
        imputeWith: imputeWith,
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
    final numeric = PrecisionCalculator.summarize(
      rows: _observations(stateManager),
      sample: formModel.sampleSizeOption,
      risk: formModel.riskLevel,
      imputeMissingData: formModel.shouldImputeMissingData,
    );
    final ranges = numeric.ranges;
    final grandMean = numeric.grandMean;
    final detectableDiffPercent = numeric.fraction;
    final upperBound = numeric.upperBound;
    final lowerBound = numeric.lowerBound;
    final imputeWith = formModel.shouldImputeMissingData && ranges.isNotEmpty
        ? grandMean
        : null;
    final factorRows = buildFactorRows(
      factors: formModel.factorDefinitions,
      manager: stateManager,
      lowerBound: lowerBound,
      upperBound: upperBound,
      imputeWith: imputeWith,
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
