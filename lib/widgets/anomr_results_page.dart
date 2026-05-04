import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import 'no_selected_project_page.dart';
import 'project_drawer.dart';

class AnomrResultsPage extends StatelessWidget {
  const AnomrResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stateManager =
        ModalRoute.of(context)!.settings.arguments as PlutoGridStateManager;

    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const NoSelectedProjectPage(title: 'Results');
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectFormModel>.value(
          value: project.formModel,
        ),
        ChangeNotifierProvider<PlutoGridStateManager>.value(
          value: stateManager,
        ),
      ],
      child: const _ResultsView(),
    );
  }
}

enum _ExportFormat {
  png('PNG image', 'png'),
  jpeg('JPEG image', 'jpg'),
  pdf('PDF document', 'pdf');

  const _ExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

class _ExportOptions {
  const _ExportOptions({required this.format, required this.includeMatrix});

  final _ExportFormat format;
  final bool includeMatrix;
}

class _FactorStats {
  const _FactorStats({
    required this.firstMean,
    required this.secondMean,
    required this.firstCount,
    required this.secondCount,
  });

  final double firstMean;
  final double secondMean;
  final int firstCount;
  final int secondCount;

  bool get hasFirst => firstCount > 0;
  bool get hasSecond => secondCount > 0;
  bool get hasBoth => hasFirst && hasSecond;
}

enum _EffectStatus { significant, notDetected, marginal, insufficient }

class _FactorRow {
  const _FactorRow({
    required this.index,
    required this.factor,
    required this.stats,
    required this.color,
    required this.status,
    required this.firstX,
    required this.secondX,
    required this.firstLabel,
    required this.secondLabel,
    required this.displayName,
  });

  final int index;
  final FactorDefinition factor;
  final _FactorStats stats;
  final Color color;
  final _EffectStatus status;
  final double firstX;
  final double secondX;
  final String firstLabel;
  final String secondLabel;
  final String displayName;

  String get conclusionText {
    switch (status) {
      case _EffectStatus.significant:
        return 'Detectable difference';
      case _EffectStatus.notDetected:
        return 'No detectable difference';
      case _EffectStatus.marginal:
        return 'Marginal';
      case _EffectStatus.insufficient:
        return 'Insufficient data';
    }
  }
}

class _ChartScale {
  const _ChartScale._(this.scale);

  factory _ChartScale.of(BuildContext context, BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final raw = width / 820;
    final clamped = raw.clamp(0.78, 1.45);
    return _ChartScale._(clamped);
  }

  final double scale;

  double get chartHeight => (340 * scale).clamp(280.0, 540.0);
  double get axisLabelFontSize => (11 * scale).clamp(10.5, 15.0);
  double get stateLabelFontSize => (12 * scale).clamp(11.0, 16.0);
  double get factorLabelFontSize => (13 * scale).clamp(12.0, 17.0);
  double get dotRadius => (5.5 * scale).clamp(4.5, 8.0);
  double get dotStroke => (2.5 * scale).clamp(2.0, 3.5);
  double get lineWidth => (3 * scale).clamp(2.5, 4.5);
  double get meanLineWidth => (1.5 * scale).clamp(1.2, 2.4);
  double get leftAxisReserve => (52 * scale).clamp(46.0, 72.0);
  double get yAxisNameReserve => (26 * scale).clamp(22.0, 36.0);
  double get stateLabelTopPad => 6.0;
  double get stateLabelRowHeight =>
      stateLabelFontSize + stateLabelTopPad + 6;
  double get factorLabelGap => (10 * scale).clamp(8.0, 14.0);
  double get factorLabelRowHeight => factorLabelFontSize + 6;
  double get bottomStateLabelReserve =>
      stateLabelRowHeight + factorLabelGap + factorLabelRowHeight;
  double get legendIconWidth => (28 * scale).clamp(24.0, 38.0);
  double get chartOuterPadding => (18 * scale).clamp(14.0, 28.0);
}

const List<Color> _factorColorPalette = <Color>[
  Color(0xFF2E7DD1), // azure
  Color(0xFFE07B2E), // amber-orange
  Color(0xFF2EA87B), // jade green
  Color(0xFF8B4FBF), // violet
  Color(0xFFC62957), // berry
  Color(0xFF3F6E8C), // slate blue
];

// X-axis layout. Values chosen so every factor-state tick lands on an integer,
// which guarantees fl_chart's SideTitles (interval: 1) generates a tick at
// every state position for any number of factors.
const double _segmentSpan =
    1.0; // distance from first to second state of same factor
const double _groupGap = 2.0; // empty gap between factor groups
const double _edgePad = 0.5; // leading/trailing padding so dots aren't clipped

class _ResultsView extends StatefulWidget {
  const _ResultsView();

  @override
  State<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<_ResultsView> {
  final GlobalKey _chartKey = GlobalKey();
  bool _isExporting = false;

  double _mean(List<double> values) {
    if (values.isEmpty) return double.nan;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<double> _collectRanges(PlutoGridStateManager manager) {
    return manager.rows
        .map(
          (row) => double.tryParse(row.cells['range']?.value?.toString() ?? ''),
        )
        .whereType<double>()
        .toList(growable: false);
  }

  _FactorStats _statsFor({
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

    return _FactorStats(
      firstMean: _mean(firstRanges),
      secondMean: _mean(secondRanges),
      firstCount: firstRanges.length,
      secondCount: secondRanges.length,
    );
  }

  /// Parses a detectable-difference label such as "±31%" into 0.31.
  double _parseDetectableDiff(String source) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(source);
    if (match == null) return 0.0;
    return double.parse(match.group(1)!) / 100.0;
  }

  String _factorDisplayName(FactorDefinition factor, int index) {
    return factor.name.trim().isEmpty ? 'Factor ${index + 1}' : factor.name;
  }

  String _stateDisplayName(String state, int fallbackIndex) {
    return state.trim().isEmpty ? '$fallbackIndex' : state;
  }

  _EffectStatus _computeStatus(
    _FactorStats stats,
    double lowerBound,
    double upperBound,
  ) {
    if (!stats.hasBoth) return _EffectStatus.insufficient;

    final firstOutside =
        stats.firstMean > upperBound || stats.firstMean < lowerBound;
    final secondOutside =
        stats.secondMean > upperBound || stats.secondMean < lowerBound;
    final firstInside = !firstOutside;
    final secondInside = !secondOutside;

    if (firstOutside && secondOutside) return _EffectStatus.significant;
    if (firstInside && secondInside) return _EffectStatus.notDetected;
    return _EffectStatus.marginal;
  }

  List<_FactorRow> _buildFactorRows({
    required List<FactorDefinition> factors,
    required PlutoGridStateManager manager,
    required double lowerBound,
    required double upperBound,
  }) {
    final rows = <_FactorRow>[];
    for (var i = 0; i < factors.length; i++) {
      final factor = factors[i];
      final firstLabel = _stateDisplayName(factor.firstState, 1);
      final secondLabel = _stateDisplayName(factor.secondState, 2);
      final stats = _statsFor(
        manager: manager,
        factorField: 'factor_$i',
        firstState: firstLabel,
        secondState: secondLabel,
      );
      final firstX = i * (_segmentSpan + _groupGap);
      final secondX = firstX + _segmentSpan;
      rows.add(
        _FactorRow(
          index: i,
          factor: factor,
          stats: stats,
          color: _factorColorPalette[i % _factorColorPalette.length],
          status: _computeStatus(stats, lowerBound, upperBound),
          firstX: firstX,
          secondX: secondX,
          firstLabel: firstLabel,
          secondLabel: secondLabel,
          displayName: _factorDisplayName(factor, i),
        ),
      );
    }
    return rows;
  }

  Future<void> _handleExport({
    required SavedProject project,
    required ProjectFormModel formModel,
    required PlutoGridStateManager stateManager,
    required double grandMean,
    required double detectableDiffPercent,
  }) async {
    final options = await showDialog<_ExportOptions>(
      context: context,
      builder: (_) => const _ExportDialog(),
    );
    if (options == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;

      final chartImage = await _captureBoundary(_chartKey);
      if (chartImage == null) {
        _showSnack('Could not capture chart.');
        return;
      }

      Uint8List fileBytes;
      switch (options.format) {
        case _ExportFormat.png:
          fileBytes = chartImage;
          break;
        case _ExportFormat.jpeg:
          fileBytes = await _reencodeAsJpeg(chartImage);
          break;
        case _ExportFormat.pdf:
          fileBytes = await _buildPdf(
            projectTitle: project.displayName,
            formModel: formModel,
            chartImage: chartImage,
            stateManager: stateManager,
            includeMatrix: options.includeMatrix,
            grandMean: grandMean,
            detectableDiffPercent: detectableDiffPercent,
          );
          break;
      }

      final suggestedName = _sanitizeFileName(
        project.displayName.isEmpty ? 'anomr_results' : project.displayName,
      );

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Export ANOMR Results',
        fileName: '$suggestedName.${options.format.extension}',
        bytes: fileBytes,
        type: FileType.custom,
        allowedExtensions: [options.format.extension],
      );

      if (savedPath != null && mounted) {
        _showSnack('Exported to $savedPath');
      }
    } catch (error) {
      if (mounted) _showSnack('Export failed: $error');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s.-]'), '').trim();
    final collapsed = cleaned.replaceAll(RegExp(r'\s+'), '_');
    return collapsed.isEmpty ? 'anomr_results' : collapsed;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Uint8List?> _captureBoundary(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final image = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List> _reencodeAsJpeg(Uint8List pngBytes) async {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) return pngBytes;
    final withBackground = img.Image(
      width: decoded.width,
      height: decoded.height,
      numChannels: 4,
    );
    img.fill(withBackground, color: img.ColorRgba8(255, 255, 255, 255));
    img.compositeImage(withBackground, decoded);
    return Uint8List.fromList(img.encodeJpg(withBackground, quality: 92));
  }

  Future<Uint8List> _buildPdf({
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
          _pdfStat('Grand Mean', _formatNumber(grandMean)),
          _pdfStat('Risk Level', formModel.riskLevel.label),
          _pdfStat(
            'Detectable Difference',
            '±${(detectableDiffPercent * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
      pw.SizedBox(height: 18),
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 12),
    ];

    if (includeMatrix) {
      sections.addAll([
        pw.Text(
          'ANOMR Data Matrix',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _buildMatrixTable(stateManager),
        pw.SizedBox(height: 24),
      ]);
    }

    sections.add(
      pw.Text(
        'Results',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    sections.add(pw.SizedBox(height: 8));
    sections.add(
      pw.ClipRect(
        child: pw.Image(pw.MemoryImage(chartImage), fit: pw.BoxFit.contain),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => sections,
      ),
    );

    return document.save();
  }

  pw.Widget _pdfStat(String label, String value) {
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

  pw.Widget _buildMatrixTable(PlutoGridStateManager manager) {
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

  String _formatNumber(double value) {
    if (value.isNaN || !value.isFinite) return '—';
    return value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = context.watch<PlutoGridStateManager>();
    final formModel = context.watch<ProjectFormModel>();
    final project = context.read<ProjectStore>().selectedProject!;

    final ranges = _collectRanges(stateManager);
    final grandMean = _mean(ranges);
    final detectableDiffPercent = _parseDetectableDiff(
      formModel.sampleSizeOption.detectableDifferenceFor(formModel.riskLevel),
    );
    final upperBound = grandMean * (1 + detectableDiffPercent);
    final lowerBound = grandMean * (1 - detectableDiffPercent);

    final factors = formModel.factorDefinitions;
    final factorRows = _buildFactorRows(
      factors: factors,
      manager: stateManager,
      lowerBound: lowerBound,
      upperBound: upperBound,
    );
    final hasEnoughData =
        ranges.isNotEmpty && grandMean.isFinite && factorRows.isNotEmpty;

    return Scaffold(
      drawer: const ProjectDrawer(),
      appBar: AppBar(
        title: Text('${project.displayName} — Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
          ),
        ],
      ),
      body: hasEnoughData
          ? LayoutBuilder(
              builder: (context, constraints) {
                final chartScale = _ChartScale.of(context, constraints);
                final horizontalPad = chartScale.chartOuterPadding + 8;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    chartScale.chartOuterPadding,
                    horizontalPad,
                    chartScale.chartOuterPadding + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderSummary(
                        grandMean: grandMean,
                        riskLevel: formModel.riskLevel,
                        detectableDiffPercent: detectableDiffPercent,
                        sampleSizeLabel: formModel.sampleSizeOption.labelFor(
                          formModel.experimentStructure,
                        ),
                      ),
                      SizedBox(height: chartScale.chartOuterPadding),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isExporting
                              ? null
                              : () => _handleExport(
                                  project: project,
                                  formModel: formModel,
                                  stateManager: stateManager,
                                  grandMean: grandMean,
                                  detectableDiffPercent: detectableDiffPercent,
                                ),
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.ios_share),
                          label: Text(_isExporting ? 'Exporting…' : 'Export'),
                        ),
                      ),
                      SizedBox(height: chartScale.chartOuterPadding + 4),
                      RepaintBoundary(
                        key: _chartKey,
                        child: _ResultsChartCard(
                          factorRows: factorRows,
                          grandMean: grandMean,
                          lowerBound: lowerBound,
                          upperBound: upperBound,
                          detectableDiffPercent: detectableDiffPercent,
                          riskLevel: formModel.riskLevel,
                          scale: chartScale,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : const _EmptyState(),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis of Mean Ranges',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(sampleSizeLabel, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stats = [
                  _Stat(
                    label: 'Grand Mean',
                    value: grandMean.toStringAsFixed(4),
                  ),
                  _Stat(label: 'Risk Level', value: riskLevel.label),
                  _Stat(
                    label: 'Detectable Difference',
                    value:
                        '±${(detectableDiffPercent * 100).toStringAsFixed(0)}%',
                  ),
                ];
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final stat in stats) ...[
                        stat,
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stats,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ResultsChartCard extends StatelessWidget {
  const _ResultsChartCard({
    required this.factorRows,
    required this.grandMean,
    required this.lowerBound,
    required this.upperBound,
    required this.detectableDiffPercent,
    required this.riskLevel,
    required this.scale,
  });

  final List<_FactorRow> factorRows;
  final double grandMean;
  final double lowerBound;
  final double upperBound;
  final double detectableDiffPercent;
  final RiskLevel riskLevel;
  final _ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(scale.chartOuterPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize:
                              (textTheme.titleLarge?.fontSize ?? 22) *
                              scale.scale.clamp(0.9, 1.2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mean ranges per factor state vs. grand mean',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: scale.chartOuterPadding),
            SizedBox(
              height: scale.chartHeight,
              child: _CombinedLineChart(
                factorRows: factorRows,
                grandMean: grandMean,
                lowerBound: lowerBound,
                upperBound: upperBound,
                detectableDiffPercent: detectableDiffPercent,
                scale: scale,
              ),
            ),
            SizedBox(height: scale.chartOuterPadding),
            _ChartLegend(
              factorRows: factorRows,
              scale: scale,
              grandMeanColor: scheme.onSurface.withValues(alpha: 0.6),
              boundColor: scheme.error,
            ),
            SizedBox(height: scale.chartOuterPadding),
            _ConclusionList(
              factorRows: factorRows,
              riskLevel: riskLevel,
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _CombinedLineChart extends StatelessWidget {
  const _CombinedLineChart({
    required this.factorRows,
    required this.grandMean,
    required this.lowerBound,
    required this.upperBound,
    required this.detectableDiffPercent,
    required this.scale,
  });

  final List<_FactorRow> factorRows;
  final double grandMean;
  final double lowerBound;
  final double upperBound;
  final double detectableDiffPercent;
  final _ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grandMeanColor = scheme.onSurface.withValues(alpha: 0.6);
    final boundColor = scheme.error;

    final lastSecondX = factorRows.isEmpty
        ? _segmentSpan
        : factorRows.last.secondX;
    final minX = -_edgePad;
    final maxX = lastSecondX + _edgePad;

    final yCandidates = <double>[
      grandMean,
      upperBound,
      lowerBound,
      for (final row in factorRows) ...[
        if (row.stats.hasFirst) row.stats.firstMean,
        if (row.stats.hasSecond) row.stats.secondMean,
      ],
    ].where((value) => value.isFinite).toList();

    var minY = yCandidates.isEmpty ? 0.0 : yCandidates.reduce(math.min);
    var maxY = yCandidates.isEmpty ? 1.0 : yCandidates.reduce(math.max);
    final spread = maxY - minY;
    if (spread == 0) {
      final adjustment = maxY.abs() * 0.1 + 1;
      minY -= adjustment;
      maxY += adjustment;
    } else {
      minY -= spread * 0.2;
      maxY += spread * 0.2;
    }

    final leftReserve = scale.leftAxisReserve;
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => spots.map((spot) {
              final match = _nearestFactorAt(spot.x);
              final label = match == null
                  ? spot.y.toStringAsFixed(4)
                  : '${match.displayName}\n'
                        '${_labelForX(spot.x, match)}: ${spot.y.toStringAsFixed(4)}';
              return LineTooltipItem(
                label,
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: scale.axisLabelFontSize,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4).abs(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: const [2, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: scheme.outline),
            left: BorderSide(color: scheme.outline),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                // Interval of half a segment so fl_chart invokes
                // getTitlesWidget at each state position (integer)
                // and at each factor midpoint (half-integer).
                interval: _segmentSpan / 2,
                reservedSize: scale.bottomStateLabelReserve,
                getTitlesWidget: (value, _) {
                  final factorMatch = _factorAtMidpoint(value);
                  if (factorMatch != null) {
                    // Render factor name on the *second* row below
                    // the state labels so the two never overlap.
                    return Padding(
                      padding: EdgeInsets.only(
                        top: scale.stateLabelRowHeight + scale.factorLabelGap,
                      ),
                      child: Text(
                        factorMatch.displayName,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: scale.factorLabelFontSize,
                          color: scheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  }
                  final stateLabel = _stateLabelForX(value);
                  if (stateLabel != null) {
                    return Padding(
                      padding: EdgeInsets.only(top: scale.stateLabelTopPad),
                      child: Text(
                        stateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: scale.stateLabelFontSize,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          leftTitles: AxisTitles(
            axisNameSize: scale.yAxisNameReserve,
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Range',
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: scale.factorLabelFontSize,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserve,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: scale.axisLabelFontSize,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: grandMean,
              color: grandMeanColor,
              strokeWidth: scale.meanLineWidth,
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: textTheme.bodySmall?.copyWith(
                  color: grandMeanColor,
                  fontWeight: FontWeight.w600,
                  fontSize: scale.axisLabelFontSize,
                ),
                labelResolver: (_) => 'Grand mean',
              ),
            ),
            HorizontalLine(
              y: upperBound,
              color: boundColor,
              strokeWidth: scale.meanLineWidth,
              dashArray: const [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: textTheme.bodySmall?.copyWith(
                  color: boundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: scale.axisLabelFontSize,
                ),
                labelResolver: (_) =>
                    '+${(detectableDiffPercent * 100).toStringAsFixed(0)}%',
              ),
            ),
            HorizontalLine(
              y: lowerBound,
              color: boundColor,
              strokeWidth: scale.meanLineWidth,
              dashArray: const [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 6, top: 2),
                style: textTheme.bodySmall?.copyWith(
                  color: boundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: scale.axisLabelFontSize,
                ),
                labelResolver: (_) =>
                    '-${(detectableDiffPercent * 100).toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        lineBarsData: [
          for (final row in factorRows)
            if (row.stats.hasBoth)
              LineChartBarData(
                spots: [
                  FlSpot(row.firstX, row.stats.firstMean),
                  FlSpot(row.secondX, row.stats.secondMean),
                ],
                isCurved: false,
                color: row.color,
                barWidth: scale.lineWidth,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: scale.dotRadius,
                    color: row.color,
                    strokeWidth: scale.dotStroke,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String? _stateLabelForX(double value) {
    for (final row in factorRows) {
      if ((value - row.firstX).abs() < 0.01) return row.firstLabel;
      if ((value - row.secondX).abs() < 0.01) return row.secondLabel;
    }
    return null;
  }

  _FactorRow? _factorAtMidpoint(double value) {
    for (final row in factorRows) {
      final midpoint = (row.firstX + row.secondX) / 2;
      if ((value - midpoint).abs() < 0.01) return row;
    }
    return null;
  }

  _FactorRow? _nearestFactorAt(double x) {
    _FactorRow? best;
    double bestDist = double.infinity;
    for (final row in factorRows) {
      final d = math.min((x - row.firstX).abs(), (x - row.secondX).abs());
      if (d < bestDist) {
        bestDist = d;
        best = row;
      }
    }
    return best;
  }

  String _labelForX(double x, _FactorRow row) {
    return (x - row.firstX).abs() < (x - row.secondX).abs()
        ? row.firstLabel
        : row.secondLabel;
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.factorRows,
    required this.scale,
    required this.grandMeanColor,
    required this.boundColor,
  });

  final List<_FactorRow> factorRows;
  final _ChartScale scale;
  final Color grandMeanColor;
  final Color boundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        for (final row in factorRows)
          _LegendChip(
            label: row.displayName,
            color: row.color,
            style: _LegendStyle.solidDots,
            scale: scale,
            onSurfaceVariant: scheme.onSurfaceVariant,
          ),
        _LegendChip(
          label: 'Grand mean',
          color: grandMeanColor,
          style: _LegendStyle.solid,
          scale: scale,
          onSurfaceVariant: scheme.onSurfaceVariant,
        ),
        _LegendChip(
          label: 'Risk bounds',
          color: boundColor,
          style: _LegendStyle.dashed,
          scale: scale,
          onSurfaceVariant: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

enum _LegendStyle { solid, dashed, solidDots }

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    required this.style,
    required this.scale,
    required this.onSurfaceVariant,
  });

  final String label;
  final Color color;
  final _LegendStyle style;
  final _ChartScale scale;
  final Color onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: scale.legendIconWidth,
          height: 14,
          child: CustomPaint(
            painter: _LegendPainter(color: color, style: style),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
            fontSize: scale.axisLabelFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LegendPainter extends CustomPainter {
  _LegendPainter({required this.color, required this.style});

  final Color color;
  final _LegendStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    if (style == _LegendStyle.dashed) {
      const dash = 4.0;
      const gap = 3.0;
      var x = 0.0;
      while (x < size.width) {
        final end = math.min(x + dash, size.width);
        canvas.drawLine(Offset(x, midY), Offset(end, midY), paint);
        x = end + gap;
      }
    } else {
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    }

    if (style == _LegendStyle.solidDots) {
      final dotPaint = Paint()..color = color;
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final dx in [3.0, size.width - 3.0]) {
        canvas.drawCircle(Offset(dx, midY), 4, dotPaint);
        canvas.drawCircle(Offset(dx, midY), 4, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LegendPainter old) {
    return old.color != color || old.style != style;
  }
}

class _ConclusionList extends StatelessWidget {
  const _ConclusionList({
    required this.factorRows,
    required this.riskLevel,
    required this.scale,
  });

  final List<_FactorRow> factorRows;
  final RiskLevel riskLevel;
  final _ChartScale scale;

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
        const SizedBox(height: 8),
        for (var i = 0; i < factorRows.length; i++) ...[
          _ConclusionRow(row: factorRows[i], scale: scale),
          if (i != factorRows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ConclusionRow extends StatelessWidget {
  const _ConclusionRow({required this.row, required this.scale});

  final _FactorRow row;
  final _ChartScale scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color statusColor;
    final IconData statusIcon;
    switch (row.status) {
      case _EffectStatus.significant:
        statusColor = scheme.error;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case _EffectStatus.notDetected:
        statusColor = scheme.primary;
        statusIcon = Icons.check_circle_outline;
        break;
      case _EffectStatus.marginal:
        statusColor = scheme.tertiary;
        statusIcon = Icons.info_outline;
        break;
      case _EffectStatus.insufficient:
        statusColor = scheme.onSurfaceVariant;
        statusIcon = Icons.help_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (12 * scale.scale).clamp(10.0, 18.0),
        vertical: (10 * scale.scale).clamp(8.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: row.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: row.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: scale.legendIconWidth,
            height: 14,
            child: CustomPaint(
              painter: _LegendPainter(
                color: row.color,
                style: _LegendStyle.solidDots,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: scale.stateLabelFontSize + 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.firstLabel} → ${row.secondLabel}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: scale.axisLabelFontSize,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (10 * scale.scale).clamp(8.0, 14.0),
              vertical: (6 * scale.scale).clamp(5.0, 10.0),
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: scale.stateLabelFontSize + 4,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  row.conclusionText,
                  style: textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: scale.axisLabelFontSize + 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  _ExportFormat _format = _ExportFormat.pdf;
  bool _includeMatrix = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pdfSelected = _format == _ExportFormat.pdf;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Export Results'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            RadioGroup<_ExportFormat>(
              groupValue: _format,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _format = value;
                  if (_format != _ExportFormat.pdf) {
                    _includeMatrix = false;
                  }
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in _ExportFormat.values)
                    RadioListTile<_ExportFormat>(
                      value: option,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(option.label),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 8),
            Opacity(
              opacity: pdfSelected ? 1 : 0.5,
              child: CheckboxListTile(
                value: _includeMatrix,
                onChanged: pdfSelected
                    ? (value) => setState(() => _includeMatrix = value ?? false)
                    : null,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Include ANOMR data matrix'),
                subtitle: Text(
                  pdfSelected
                      ? 'Matrix will be placed before the graph.'
                      : 'Only available when exporting to PDF.',
                  style: textTheme.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            _ExportOptions(
              format: _format,
              includeMatrix: _includeMatrix && pdfSelected,
            ),
          ),
          icon: const Icon(Icons.download),
          label: const Text('Export'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'No range data available',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter at least one range value in the ANOMR matrix to see results.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
