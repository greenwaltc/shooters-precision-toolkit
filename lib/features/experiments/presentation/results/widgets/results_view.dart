import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/foundation/diagnostics.dart';
import '../../../../../shared/foundation/file_saver.dart';
import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/app_bar_actions.dart';
import '../../../../../shared/ui/app_brand_bar.dart';
import '../../../../../shared/ui/app_nav_chrome.dart';
import '../../../../../shared/ui/navigation/app_routes.dart';
import '../../../../../shared/ui/theme/chart/chart_layout.dart';
import '../../../../../shared/ui/theme/chart/chart_scale.dart';
import '../../../../../shared/ui/theme/layout/app_layout.dart';
import '../../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../../matrix/services/matrix_grid_data_builder.dart';
import '../../project_store.dart';
import '../../test_design/project_form_model.dart';
import '../../widgets/workspace_footer.dart';
import '../models/anomr_summary.dart';
import '../models/export_options.dart';
import '../services/anomr_calculator.dart';
import '../services/export_controller.dart';
import 'empty_results_state.dart';
import 'export_action_button.dart';
import 'export_dialog.dart';
import 'header_summary.dart';
import 'results_chart_card.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

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
        final label = context.l10n.projectResults(project.displayName);
        final hasLeading = AppNavChrome.canPop(context);
        final store = context.read<ProjectStore>();
        final actionItems = [
          AppBarActionBar.instructions(context),
          AppBarActionBar.contact(context),
          AppBarActionBar.donations(context),
          AppBarActionItem(
            label: context.l10n.projects,
            icon: Icons.home_outlined,
            tooltip: context.l10n.projects,
            onPressed: () => _goHome(context, store, stateManager),
          ),
          ...AppBarActionBar.signOutActions(context),
        ];
        final actionsMetrics = AppBarActionsMetrics.of(
          context,
          layout: layout,
          items: actionItems,
          hasLeading: hasLeading,
        );
        final titleMetrics = AppBrandTitleMetrics.of(
          context,
          label: label,
          titleMaxWidth: actionsMetrics.titleMaxWidth,
          logoScale: 1.5,
        );

        return Scaffold(
          appBar: _ResultsAppBar(
            label: label,
            layout: layout,
            hasLeading: hasLeading,
            actionItems: actionItems,
            titleMetrics: titleMetrics,
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
              : const SafeArea(bottom: false, child: EmptyResultsState()),
          bottomNavigationBar: const WorkspaceFooter(),
        );
      },
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
    if (!context.mounted) {
      return;
    }
    await AppRoutes.goToProjects(navigator);
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
    if (options == null || !mounted) {
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    setState(() => _isExporting = true);
    try {
      // Wait for any setState-triggered repaints to flush before exporting.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      final controller = ExportController(
        fileSaver: context.read<FileSaver>(),
        diagnostics: context.read<Diagnostics>(),
        isActive: () =>
            mounted &&
            context.read<ProjectStore>().selectedProject?.id == project.id,
        overlay: overlay,
        formModel: formModel,
        stateManager: stateManager,
        project: project,
      );
      final outcome = await controller.run(options);

      if (!mounted) {
        return;
      }
      switch (outcome) {
        case ExportSucceeded(:final path):
          _showSnack(context.l10n.exportedTo(path));
        case ExportCancelled():
          break;
        case ExportFailed(:final message):
          _showSnack(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ResultsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ResultsAppBar({
    required this.label,
    required this.layout,
    required this.hasLeading,
    required this.actionItems,
    required this.titleMetrics,
  });

  final String label;
  final AppLayoutMetrics layout;
  final bool hasLeading;
  final List<AppBarActionItem> actionItems;
  final AppBrandTitleMetrics titleMetrics;

  @override
  Size get preferredSize => Size.fromHeight(titleMetrics.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: titleMetrics.toolbarHeight,
      automaticallyImplyLeading: false,
      leading: AppNavChrome.backLeading(context),
      title: AppBrandTitle(label: label, metrics: titleMetrics),
      actions: AppBarActionBar.build(
        context,
        layout: layout,
        items: actionItems,
        hasLeading: hasLeading,
      ),
    );
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
        layout.pageGutterVertical,
        layout.pageGutter,
        layout.pageGutterVertical +
            (layout.preferCompactChrome ? AppSpacing.sm : AppSpacing.xl),
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

    final desktop = MediaQuery.sizeOf(context).width >= 1024;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeader(summary)),
              const SizedBox(width: AppSpacing.xl),
              ExportActionButton(
                onPressed: onExportPressed,
                isExporting: isExporting,
              ),
            ],
          )
        else ...[
          ExportActionButton(
            onPressed: onExportPressed,
            isExporting: isExporting,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHeader(summary),
        ],
        SizedBox(
          height: desktop ? 12 : scale.chartOuterPadding + AppSpacing.sm,
        ),
        _buildChart(summary, scale),
        SizedBox(height: scale.chartOuterPadding),
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
