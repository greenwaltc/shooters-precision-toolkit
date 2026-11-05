import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/pdf/pdf_styles.dart';
import '../../matrix/services/matrix_grid_data_builder.dart';
import '../../test_design/project_form_model.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Builds a PDF document containing the export-rendered chart image and an
/// optional ANOMR data table.
///
/// All visual decisions (margins, typography, table borders) come from
/// [PdfStyles]. Chart and table content use fixed export layout rules that do
/// not depend on the current screen size or platform.
class AnomrPdfBuilder {
  const AnomrPdfBuilder._();

  /// Builds PDF bytes containing the chart and project summary.
  ///
  /// Set [includeMatrix] to include the measurement table.
  /// [detectableDiffPercent] is a fraction of the grand mean.
  static Future<Uint8List> build({
    required String projectTitle,
    required ProjectFormModel formModel,
    required Uint8List chartImage,
    required PlutoGridStateManager stateManager,
    required bool includeMatrix,
    required double grandMean,
    required double detectableDiffPercent,
  }) async {
    final document = pw.Document();
    final sections = <pw.Widget>[
      ..._headerSection(
        projectTitle: projectTitle,
        riskLevel: formModel.riskLevel,
        grandMean: grandMean,
        detectableDiffPercent: detectableDiffPercent,
      ),
      if (includeMatrix) ..._matrixSection(stateManager),
      ..._chartSection(chartImage),
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: PdfStyles.pageMargin,
        build: (_) => sections,
      ),
    );

    return document.save();
  }

  static List<pw.Widget> _headerSection({
    required String projectTitle,
    required RiskLevel riskLevel,
    required double grandMean,
    required double detectableDiffPercent,
  }) {
    return [
      pw.Text(
        projectTitle.isEmpty ? AppCopy.english.results : projectTitle,
        style: PdfStyles.title(),
      ),
      pw.SizedBox(height: PdfStyles.gapSm),
      pw.Text(AppCopy.english.projectParameters, style: PdfStyles.subtitle()),
      pw.SizedBox(height: PdfStyles.gapLg),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _statBlock(AppCopy.english.grandMean, _formatNumber(grandMean)),
          _statBlock(AppCopy.english.riskLevel, riskLevel.label),
          _statBlock(
            AppCopy.english.detectableDifferenceMessage,
            SampleSizeLabels.formatFraction(detectableDiffPercent),
          ),
        ],
      ),
      pw.SizedBox(height: PdfStyles.gapXl),
      pw.Divider(color: PdfStyles.dividerColor),
      pw.SizedBox(height: PdfStyles.gapLg),
    ];
  }

  static List<pw.Widget> _matrixSection(PlutoGridStateManager manager) {
    return [
      pw.Text(AppCopy.english.dataMatrix, style: PdfStyles.sectionHeader()),
      pw.SizedBox(height: PdfStyles.gapMd),
      _matrixTable(manager),
      pw.SizedBox(height: PdfStyles.gapXxl),
    ];
  }

  static List<pw.Widget> _chartSection(Uint8List chartImage) {
    return [
      pw.Text(AppCopy.english.results, style: PdfStyles.sectionHeader()),
      pw.SizedBox(height: PdfStyles.gapMd),
      pw.ClipRect(
        child: pw.Image(pw.MemoryImage(chartImage), fit: pw.BoxFit.contain),
      ),
    ];
  }

  static pw.Widget _statBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: PdfStyles.statLabel()),
        pw.SizedBox(height: PdfStyles.gapXs),
        pw.Text(value, style: PdfStyles.statValue()),
      ],
    );
  }

  static pw.Widget _matrixTable(PlutoGridStateManager manager) {
    final columns = manager.columns;
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfStyles.tableBorderColor,
        width: PdfStyles.tableBorderWidth,
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfStyles.tableHeaderFill),
          children: columns
              .map(
                (column) => pw.Padding(
                  padding: PdfStyles.tableHeaderCell,
                  child: pw.Text(
                    column.title,
                    style: PdfStyles.tableHeaderCellText(),
                  ),
                ),
              )
              .toList(),
        ),
        ..._exportRows(manager).map(
          (row) => pw.TableRow(
            children: columns.map((column) {
              final value = row.cells[column.field]?.value;
              return pw.Padding(
                padding: PdfStyles.tableBodyCell,
                child: pw.Text(
                  value?.toString() ?? '',
                  style: PdfStyles.tableBodyCellText(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    if (value.isNaN || !value.isFinite) {
      return '—';
    }
    return value.toStringAsFixed(4);
  }

  /// Rows in stable storage-index order so PDF matrix tables are identical
  /// regardless of on-screen randomization or viewport.
  static List<PlutoRow> _exportRows(PlutoGridStateManager manager) {
    final rows = List<PlutoRow>.from(manager.refRows);
    rows.sort((a, b) => _storageIndexFor(a).compareTo(_storageIndexFor(b)));
    return rows;
  }

  static int _storageIndexFor(PlutoRow row) {
    return MatrixGridDataBuilder.cellIntValue(row.cells['storage']) ??
        ((MatrixGridDataBuilder.cellIntValue(row.cells['row']) ?? 1) - 1);
  }
}
