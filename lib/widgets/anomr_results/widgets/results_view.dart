// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../../../help/help_access.dart';
import '../../../model/project_form_model.dart';
import '../../../model/project_store.dart';
import '../../../styles/chart/chart_layout.dart';
import '../../../styles/chart/chart_scale.dart';
import '../../../styles/layout/app_layout.dart';
import '../../../styles/tokens/app_spacing.dart';
import '../../../navigation/app_routes.dart';
import '../../anomr_matrix/services/matrix_grid_data_builder.dart';
import '../../app_brand_bar.dart';
import '../../app_copyright_footer.dart';
import '../../app_nav_chrome.dart';
import '../../project_drawer.dart';
import '../models/anomr_summary.dart';
import '../models/export_options.dart';
import '../services/anomr_calculator.dart';
import '../services/export_controller.dart';
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
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final stateManager = context.watch<PlutoGridStateManager>();
    final formModel = context.watch<ProjectFormModel>();
    final project = context.read<ProjectStore>().selectedProject!;

    final previewSummary = AnomrCalculator.summarize(
      formModel: formModel,
      stateManager: stateManager,
    );

    return AppLayoutBuilder(
      builder: (context, layout) {
        return Scaffold(
          drawer: const ProjectDrawer(),
          appBar: _ResultsAppBar(
            displayName: project.displayName,
            layout: layout,
          ),
          body: previewSummary.hasEnoughData
              ? _ResultsBody(
                  formModel: formModel,
                  stateManager: stateManager,
                  isExporting: _isExporting,
                  onExportPressed: () => _onExportPressed(
                    formModel: formModel,
                    stateManager: stateManager,
                  ),
                )
              : const SafeArea(
                  bottom: false,
                  child: EmptyResultsState(),
                ),
          floatingActionButton: helpFabFor(layout),
          floatingActionButtonLocation: helpFabLocation,
          bottomNavigationBar: const AppCopyrightFooter(),
        );
      },
    );
  }

  Future<void> _onExportPressed({
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

    final overlay = Overlay.of(context, rootOverlay: true);

    setState(() => _isExporting = true);
    try {
      // Wait for any setState-triggered repaints to flush before exporting.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      final controller = ExportController(
        overlay: overlay,
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
  const _ResultsAppBar({required this.displayName, required this.layout});

  final String displayName;
  final AppLayoutMetrics layout;

  @override
  Size get preferredSize => const Size.fromHeight(AppBrandTitle.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProjectStore>();
    final stateManager = context.read<PlutoGridStateManager>();

    return AppBar(
      toolbarHeight: AppBrandTitle.toolbarHeight,
      automaticallyImplyLeading: false,
      leading: AppNavChrome.backLeading(context),
      title: AppBrandTitle(label: '$displayName — Results'),
      actions: [
        ...helpAppBarActionsFor(layout),
        IconButton(
          tooltip: 'Projects',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => _goHome(context, store, stateManager),
        ),
        AppNavChrome.drawerAction(),
      ],
    );
  }

  Future<void> _goHome(
    BuildContext context,
    ProjectStore store,
    PlutoGridStateManager stateManager,
  ) async {
    final project = store.selectedProject;
    if (project != null) {
      // Results holds the live matrix manager; sync it before clearing the
      // stack so Group Size values cannot be lost when the matrix is disposed.
      MatrixGridDataBuilder.syncMatrixStateFromGrid(
        project: project,
        manager: stateManager,
      );
    }

    final navigator = Navigator.of(context);
    await store.persistSelectedProject();
    if (!context.mounted) return;
    await AppRoutes.goToProjects(navigator);
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.formModel,
    required this.stateManager,
    required this.isExporting,
    required this.onExportPressed,
  });

  final ProjectFormModel formModel;
  final PlutoGridStateManager stateManager;
  final bool isExporting;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AppLayoutBuilder(
        builder: (context, layout) => _buildScrollView(layout),
      ),
    );
  }

  Widget _buildScrollView(AppLayoutMetrics layout) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        layout.pageGutter,
        layout.pageGutter,
        layout.pageGutter,
        layout.pageGutter + AppSpacing.xl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.resultsMaxWidth),
          child: LayoutBuilder(builder: _buildResultsColumn),
        ),
      ),
    );
  }

  Widget _buildResultsColumn(BuildContext context, BoxConstraints constraints) {
    final scale = ChartScale.of(context, constraints);
    final summary = _summaryFor(scale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(summary),
        SizedBox(height: scale.chartOuterPadding),
        ExportActionButton(
          onPressed: onExportPressed,
          isExporting: isExporting,
        ),
        SizedBox(height: scale.chartOuterPadding + AppSpacing.sm),
        _buildChart(summary, scale),
      ],
    );
  }

  AnomrSummary _summaryFor(ChartScale scale) {
    return AnomrCalculator.summarize(
      formModel: formModel,
      stateManager: stateManager,
      layout: scale.isCompact ? ChartLayout.compact : ChartLayout.standard,
    );
  }

  Widget _buildHeader(AnomrSummary summary) {
    return HeaderSummary(
      grandMean: summary.grandMean,
      riskLevel: formModel.riskLevel,
      detectableDiffPercent: summary.detectableDiffPercent,
      sampleSizeLabel: formModel.sampleSizeOption.labelFor(
        formModel.experimentStructure,
      ),
    );
  }

  Widget _buildChart(AnomrSummary summary, ChartScale scale) {
    return ResultsChartCard(
      factorRows: summary.factorRows,
      grandMean: summary.grandMean,
      lowerBound: summary.lowerBound,
      upperBound: summary.upperBound,
      detectableDiffPercent: summary.detectableDiffPercent,
      riskLevel: formModel.riskLevel,
      scale: scale,
    );
  }
}
