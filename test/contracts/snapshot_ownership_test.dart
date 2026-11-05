import 'dart:typed_data';

import 'package:bramwells_precision_test_kit/features/experiments/domain/sample_size_catalog.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/models/matrix_grid_data.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/services/matrix_grid_history.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/models/anomr_summary.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/models/factor_row.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/services/anomr_export_service.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/shared/ui/product_configuration.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/theme_extensions/anomr_chart_theme.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/theme_extensions/factor_palette_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

void main() {
  test('result and grid snapshots own their row ordering', () {
    final bytes = Uint8List.fromList([1, 2]);
    final artifact = ExportArtifact(bytes: bytes, extension: 'png');
    bytes[0] = 9;
    expect(artifact.bytes, [1, 2]);
    expect(() => artifact.bytes[0] = 5, throwsUnsupportedError);
    final ranges = [1.0, 2.0];
    final factors = <FactorRow>[];
    final summary = AnomrSummary(
      ranges: ranges,
      grandMean: 1.5,
      detectableDiffPercent: .1,
      lowerBound: 1,
      upperBound: 2,
      factorRows: factors,
    );
    ranges.clear();
    expect(summary.ranges, [1.0, 2.0]);
    expect(() => summary.ranges.clear(), throwsUnsupportedError);
    expect(() => summary.factorRows.clear(), throwsUnsupportedError);
    final rows = [PlutoRow(cells: {})];
    final grid = MatrixGridData(rows: rows, totalSamples: 1);
    rows.clear();
    expect(grid.rows, hasLength(1));
    expect(() => grid.rows.clear(), throwsUnsupportedError);
    // Pluto owns mutable cells, while snapshot list ordering is protected.
    grid.rows.first.cells['range'] = PlutoCell(value: '2');
    expect(grid.rows.first.cells['range']!.value, '2');
    final changes = [
      const MatrixRangeChange(rowIdx: 0, previousValue: '1', newValue: '2'),
    ];
    final history = MatrixHistoryEntry(changes);
    changes.clear();
    expect(history.changes, hasLength(1));
    expect(() => history.changes.clear(), throwsUnsupportedError);
  });

  test('configuration copies caller-owned maps and lists', () {
    final calibration = {RiskLevel.tenPercent: .1};
    final sample = SampleSizeOption(
      numFactors: 1,
      numSets: 4,
      family: SampleSizeFamily.simpleComparison,
      detectableDifferences: calibration,
    );
    calibration.clear();
    expect(sample.detectableDifferenceFor(RiskLevel.tenPercent), .1);
    expect(() => sample.detectableDifferences.clear(), throwsUnsupportedError);
    expect(
      () => SampleSizeCatalog.optionsFor(
        factorCount: 1,
        riskLevel: RiskLevel.tenPercent,
      ).clear(),
      throwsUnsupportedError,
    );
    final sourceFlags = {FeatureFlag.themeModeToggle: true};
    final flags = FeatureFlags(values: sourceFlags);
    sourceFlags.clear();
    expect(flags.isEnabled(FeatureFlag.themeModeToggle), isTrue);
    final colors = [Colors.blue];
    final palette = FactorPaletteTheme(colors: colors);
    colors.clear();
    expect(palette.colorFor(0), Colors.blue);
    expect(() => palette.colors.clear(), throwsUnsupportedError);
    expect(() => FactorPaletteTheme(colors: []), throwsArgumentError);
    final dashes = [2, 4];
    final chart = AnomrChartTheme(
      dotOutlineColor: Colors.white,
      gridLineOpacity: .1,
      referenceLineOpacity: .3,
      gridLineDashArray: dashes,
      boundLineDashArray: dashes,
    );
    dashes.clear();
    expect(chart.gridLineDashArray, [2, 4]);
    expect(() => chart.boundLineDashArray.clear(), throwsUnsupportedError);
  });
}
