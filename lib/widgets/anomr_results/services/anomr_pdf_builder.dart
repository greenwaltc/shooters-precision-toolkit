import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';

/// Builds a PDF document containing the captured chart image and an optional
/// ANOMR data table.
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
        margin: const pw.EdgeInsets.all(36),
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
        projectTitle.isEmpty ? 'ANOMR Results' : projectTitle,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Analysis of Mean Ranges',
        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _statBlock('Grand Mean', _formatNumber(grandMean)),
          _statBlock('Risk Level', riskLevel.label),
          _statBlock(
            'Detectable Difference',
            '±${(detectableDiffPercent * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
      pw.SizedBox(height: 18),
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 12),
    ];
  }

  static List<pw.Widget> _matrixSection(PlutoGridStateManager manager) {
    return [
      pw.Text(
        'ANOMR Data Matrix',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      _matrixTable(manager),
      pw.SizedBox(height: 24),
    ];
  }

  static List<pw.Widget> _chartSection(Uint8List chartImage) {
    return [
      pw.Text(
        'Results',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.ClipRect(
        child: pw.Image(pw.MemoryImage(chartImage), fit: pw.BoxFit.contain),
      ),
    ];
  }

  static pw.Widget _statBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _matrixTable(PlutoGridStateManager manager) {
    final columns = manager.columns;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: columns
              .map(
                (column) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: pw.Text(
                    column.title,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
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
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: pw.Text(
                  value?.toString() ?? '',
                  style: const pw.TextStyle(fontSize: 10),
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
