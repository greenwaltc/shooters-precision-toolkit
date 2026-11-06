import 'package:pluto_grid/pluto_grid.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../domain/range_value_parser.dart';
import '../../saved_project.dart';
import '../../test_design/project_form_model.dart';
import '../models/matrix_grid_data.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Builds and addresses the non-visual data used by the ANOMR matrix grid.
class MatrixGridDataBuilder {
  const MatrixGridDataBuilder._();

  /// Creates the Pluto row payload for the currently selected project setup.
  static MatrixGridData build({
    required ProjectFormModel formModel,
    required SavedProject project,
  }) {
    final factors = formModel.factorDefinitions;
    final combinations = generateCombinations(factors);
    final rangesPerGroup = formModel.sampleSizeOption.rangesPerGroup.toInt();

    return MatrixGridData(
      rows: _buildRows(
        formModel: formModel,
        project: project,
        combinations: combinations,
        rangesPerGroup: rangesPerGroup,
      ),
      totalSamples: formModel.sampleSizeOption.totalSamples,
    );
  }

  /// Returns the persisted range key for a rendered row.
  ///
  /// The key is derived from the stable `storage` cell (the canonical sample
  /// index) so it survives row reordering (e.g. randomization). The displayed
  /// "Run Order" column is purely positional and must not drive persistence.
  static String storageKeyForRow(PlutoRow row) {
    final storageIndex = cellIntValue(row.cells['storage']);
    if (storageIndex != null) {
      return 'range_$storageIndex';
    }

    final rowNumber = cellIntValue(row.cells['row']) ?? 1;
    return 'range_${rowNumber - 1}';
  }

  /// Copies the Group Size cells from [rows] into the project's saved matrix.
  ///
  /// Returns `true` when at least one stored value changed. Callers should
  /// persist afterwards when they need the update durable.
  static bool syncMatrixStateFromRows({
    required SavedProject project,
    required Iterable<PlutoRow> rows,
  }) {
    var changed = false;
    for (final row in rows) {
      final storageKey = storageKeyForRow(row);
      final normalized = RangeValueParser.parse(
        row.cells['range']?.value,
      ).displayValue;
      final stored = project.matrixState[storageKey]?.toString();
      final left = (stored == null || stored.isEmpty) ? null : stored;
      final right = (normalized == null || normalized.isEmpty)
          ? null
          : normalized;
      if (left == right) {
        continue;
      }

      project.matrixState[storageKey] = normalized;
      changed = true;
    }
    return changed;
  }

  /// Convenience wrapper around [syncMatrixStateFromRows] for a live grid.
  static bool syncMatrixStateFromGrid({
    required SavedProject project,
    required PlutoGridStateManager manager,
  }) {
    return syncMatrixStateFromRows(project: project, rows: manager.rows);
  }

  /// Returns the integer value stored in [cell], if it can be parsed.
  static int? cellIntValue(PlutoCell? cell) {
    final value = cell?.value;
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  /// Human-readable matrix column label for a factor.
  static String factorLabel(FactorDefinition factor, int index) {
    final name = factor.name.trim();
    return name.isEmpty ? AppCopy.english.factorNumber(index + 1) : name;
  }

  /// Generates factor-state combinations in the order used by saved range keys.
  ///
  /// The last factor changes fastest in this order. Factorial rows display
  /// the same combinations in a different order without changing their keys.
  static List<List<String>> generateCombinations(
    List<FactorDefinition> factors,
  ) {
    if (factors.isEmpty) {
      return const [[]];
    }

    var results = const <List<String>>[[]];
    for (final factor in factors) {
      results = _appendFactorStates(results, factor);
    }
    return results;
  }

  static List<PlutoRow> _buildRows({
    required ProjectFormModel formModel,
    required SavedProject project,
    required List<List<String>> combinations,
    required int rangesPerGroup,
  }) {
    final rows = <PlutoRow>[];
    final stateMajorOrder =
        formModel.experimentStructure == ExperimentStructure.simpleABComparison;

    if (stateMajorOrder) {
      _addStateMajorRows(
        rows,
        formModel,
        project,
        combinations,
        rangesPerGroup,
      );
    } else {
      _addReplicateMajorRows(
        rows,
        formModel,
        project,
        combinations,
        rangesPerGroup,
      );
    }

    return rows;
  }

  static void _addStateMajorRows(
    List<PlutoRow> rows,
    ProjectFormModel formModel,
    SavedProject project,
    List<List<String>> combinations,
    int rangesPerGroup,
  ) {
    for (var comboIdx = 0; comboIdx < combinations.length; comboIdx++) {
      for (var blockIdx = 0; blockIdx < rangesPerGroup; blockIdx++) {
        rows.add(
          _buildRow(
            formModel,
            project,
            combinations,
            comboIdx,
            blockIdx,
            runOrder: rows.length + 1,
          ),
        );
      }
    }
  }

  static void _addReplicateMajorRows(
    List<PlutoRow> rows,
    ProjectFormModel formModel,
    SavedProject project,
    List<List<String>> combinations,
    int rangesPerGroup,
  ) {
    final combinationOrder = _firstFactorFastestOrder(combinations.length);
    for (var blockIdx = 0; blockIdx < rangesPerGroup; blockIdx++) {
      for (final comboIdx in combinationOrder) {
        rows.add(
          _buildRow(
            formModel,
            project,
            combinations,
            comboIdx,
            blockIdx,
            runOrder: rows.length + 1,
          ),
        );
      }
    }
  }

  /// Interleaves the two halves of each binary factor's stored combinations.
  /// This reverses which factor changes fastest while retaining storage indices.
  static List<int> _firstFactorFastestOrder(int combinationCount) {
    var order = [0];
    for (var stride = 1; stride < combinationCount; stride *= 2) {
      order = [
        for (final index in order) ...[index, index + stride],
      ];
    }
    return order;
  }

  static PlutoRow _buildRow(
    ProjectFormModel formModel,
    SavedProject project,
    List<List<String>> combinations,
    int comboIdx,
    int blockIdx, {
    required int runOrder,
  }) {
    final combo = combinations[comboIdx];
    final rangeIndex = formModel.sampleSizeOption.matrixRangeIndex(
      comboIdx: comboIdx,
      blockIdx: blockIdx,
      comboCount: combinations.length,
      structure: formModel.experimentStructure,
    );

    return PlutoRow(
      cells: {
        'row': PlutoCell(value: runOrder),
        'group': PlutoCell(value: blockIdx + 1),
        // Stable, hidden persistence index (no matching column).
        'storage': PlutoCell(value: rangeIndex),
        for (var factorIdx = 0; factorIdx < combo.length; factorIdx++)
          'factor_$factorIdx': PlutoCell(value: combo[factorIdx]),
        'range': PlutoCell(
          // Pluto's text editor stringifies the value, including null.
          value: project.matrixState['range_$rangeIndex']?.toString() ?? '',
        ),
      },
    );
  }

  static List<List<String>> _appendFactorStates(
    List<List<String>> combinations,
    FactorDefinition factor,
  ) {
    final firstState = _stateLabel(factor.firstState, 1);
    final secondState = _stateLabel(factor.secondState, 2);

    return [
      for (final combination in combinations) ...[
        [...combination, firstState],
        [...combination, secondState],
      ],
    ];
  }

  static String _stateLabel(String value, int fallbackIndex) {
    return value.trim().isEmpty ? '$fallbackIndex' : value;
  }
}
