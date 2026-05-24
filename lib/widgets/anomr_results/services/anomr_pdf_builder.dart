// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/pdf/pdf_styles.dart';

/// Builds a PDF document containing the captured chart image and an optional
/// ANOMR data table.
///
/// All visual decisions (margins, typography, table borders) come from
/// [PdfStyles] so the export reads as a sibling of the in-app card.
class AnomrPdfBuilder {
  const AnomrPdfBuilder._();

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
        projectTitle.isEmpty ? 'Results' : projectTitle,
        style: PdfStyles.title(),
      ),
      pw.SizedBox(height: PdfStyles.gapSm),
      pw.Text('Project Parameters', style: PdfStyles.subtitle()),
      pw.SizedBox(height: PdfStyles.gapLg),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _statBlock('Grand Mean', _formatNumber(grandMean)),
          _statBlock('Risk Level', riskLevel.label),
          _statBlock(
            'Detectable Difference',
            SampleSizeOption.formatFraction(detectableDiffPercent),
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
      pw.Text('Data Matrix', style: PdfStyles.sectionHeader()),
      pw.SizedBox(height: PdfStyles.gapMd),
      _matrixTable(manager),
      pw.SizedBox(height: PdfStyles.gapXxl),
    ];
  }

  static List<pw.Widget> _chartSection(Uint8List chartImage) {
    return [
      pw.Text('Results', style: PdfStyles.sectionHeader()),
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
        ...manager.rows.map(
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
    if (value.isNaN || !value.isFinite) return '—';
    return value.toStringAsFixed(4);
  }
}
