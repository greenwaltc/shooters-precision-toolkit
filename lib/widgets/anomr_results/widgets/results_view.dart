import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../../../model/project_form_model.dart';
import '../../../model/project_store.dart';
import '../../project_drawer.dart';
import '../models/anomr_summary.dart';
import '../models/export_options.dart';
import '../services/anomr_calculator.dart';
import '../services/export_controller.dart';
import '../theme/chart_scale.dart';
import 'empty_results_state.dart';
import 'export_action_button.dart';
import 'export_dialog.dart';
import 'header_summary.dart';
import 'results_chart_card.dart';

/// Body widget rendered when a project is selected. Wires the calculator's
/// summary to the visual building blocks and drives the export flow.
class ResultsView extends StatefulWidget {
  const ResultsView({super.key});

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  final GlobalKey _chartKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final stateManager = context.watch<PlutoGridStateManager>();
    final formModel = context.watch<ProjectFormModel>();
    final project = context.read<ProjectStore>().selectedProject!;

    final summary = AnomrCalculator.summarize(
      formModel: formModel,
      stateManager: stateManager,
    );

    return Scaffold(
      drawer: const ProjectDrawer(),
      appBar: _ResultsAppBar(displayName: project.displayName),
      body: summary.hasEnoughData
          ? _ResultsBody(
              summary: summary,
              formModel: formModel,
              chartKey: _chartKey,
              isExporting: _isExporting,
              onExportPressed: () => _onExportPressed(
                summary: summary,
                formModel: formModel,
                stateManager: stateManager,
              ),
            )
          : const EmptyResultsState(),
    );
  }

  Future<void> _onExportPressed({
    required AnomrSummary summary,
    required ProjectFormModel formModel,
    required PlutoGridStateManager stateManager,
  }) async {
    // Capture the project synchronously up-front so we don't reach back into
    // `context` after awaiting.
    final project = context.read<ProjectStore>().selectedProject!;

    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (_) => const ExportDialog(),
    );
    if (options == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      // Wait for any setState-triggered repaints to flush before capturing.
      await WidgetsBinding.instance.endOfFrame;

      final controller = ExportController(
        chartKey: _chartKey,
        summary: summary,
        formModel: formModel,
        stateManager: stateManager,
        project: project,
      );
      final outcome = await controller.run(options);

      if (!mounted) return;
      switch (outcome) {
        case ExportSucceeded(:final path):
          _showSnack('Exported to $path');
        case ExportCancelled():
          break;
        case ExportFailed(:final message):
          _showSnack(message);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ResultsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ResultsAppBar({required this.displayName});

  final String displayName;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('$displayName — Results'),
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
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.summary,
    required this.formModel,
    required this.chartKey,
    required this.isExporting,
    required this.onExportPressed,
  });

  final AnomrSummary summary;
  final ProjectFormModel formModel;
  final GlobalKey chartKey;
  final bool isExporting;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ChartScale.of(context, constraints);
        final horizontalPad = scale.chartOuterPadding + 8;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            scale.chartOuterPadding,
            horizontalPad,
            scale.chartOuterPadding + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderSummary(
                grandMean: summary.grandMean,
                riskLevel: formModel.riskLevel,
                detectableDiffPercent: summary.detectableDiffPercent,
                sampleSizeLabel: formModel.sampleSizeOption.labelFor(
                  formModel.experimentStructure,
                ),
              ),
              SizedBox(height: scale.chartOuterPadding),
              ExportActionButton(
                onPressed: onExportPressed,
                isExporting: isExporting,
              ),
              SizedBox(height: scale.chartOuterPadding + 4),
              RepaintBoundary(
                key: chartKey,
                child: ResultsChartCard(
                  factorRows: summary.factorRows,
                  grandMean: summary.grandMean,
                  lowerBound: summary.lowerBound,
                  upperBound: summary.upperBound,
                  detectableDiffPercent: summary.detectableDiffPercent,
                  riskLevel: formModel.riskLevel,
                  scale: scale,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
