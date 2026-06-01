// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../config/project_configuration.dart';
import '../help/help_access.dart';
import '../model/project_form_model.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../navigation/app_routes.dart';
import '../styles/layout/app_layout.dart';
import '../styles/layout/app_viewport.dart';
import 'anomr_results/services/anomr_calculator.dart';
import '../styles/theme_extensions/pluto_grid_theme.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';
import 'project_drawer.dart';
import 'range_entry_sheet.dart';
import 'no_selected_project_page.dart';

class AnomrMatrix extends StatelessWidget {
  const AnomrMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const NoSelectedProjectPage(title: 'Data Matrix');
    }

    if (!project.setupComplete) {
      return const _ProjectSetupRequiredRedirect();
    }

    return ChangeNotifierProvider<ProjectFormModel>.value(
      value: project.formModel,
      child: _AnomrMatrixScaffold(project: project),
    );
  }
}

class _ProjectSetupRequiredRedirect extends StatefulWidget {
  const _ProjectSetupRequiredRedirect();

  @override
  State<_ProjectSetupRequiredRedirect> createState() =>
      _ProjectSetupRequiredRedirectState();
}

class _ProjectSetupRequiredRedirectState
    extends State<_ProjectSetupRequiredRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.projectForm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AnomrMatrixScaffold extends StatelessWidget {
  const _AnomrMatrixScaffold({required this.project});

  final SavedProject project;

  @override
  Widget build(BuildContext context) {
    final formModel = context.watch<ProjectFormModel>();
    final store = context.read<ProjectStore>();

    return AppLayoutBuilder(
      builder: (context, layout) {
        return Scaffold(
          drawer: const ProjectDrawer(),
          appBar: AppBar(
            title: Text(project.displayName),
            actions: [
              ...helpAppBarActionsFor(layout, preferAppBar: true),
              IconButton(
                tooltip: 'Projects',
                onPressed: () => _goHome(context, store),
                icon: const Icon(Icons.home_outlined),
              ),
              IconButton(
                tooltip: 'Project setup',
                onPressed: () => _goToProjectSetup(context, store),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: SafeArea(
            minimum: AppViewport.safeAreaMinimum,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.pageGutter,
                      layout.isMobile ? AppSpacing.sm : AppSpacing.md,
                      layout.pageGutter,
                      AppSpacing.lg,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: layout.matrixHeaderMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factors and Ranges',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(formModel.experimentStructure.label),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.pageGutter,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.matrixHeaderMaxWidth,
                          ),
                          child: AnomrMatrixGrid(
                            key: ValueKey(
                              '${project.id}_${formModel.experimentStructure}_${formModel.sampleSizeOption.totalSamples}_${layout.isMobile}',
                            ),
                            project: project,
                            isMobile: layout.isMobile,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  Future<void> _goHome(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    await store.persistSelectedProject();
    navigator.pushNamedAndRemoveUntil(AppRoutes.projects, (_) => false);
  }

  Future<void> _goToProjectSetup(
    BuildContext context,
    ProjectStore store,
  ) async {
    final navigator = Navigator.of(context);
    await store.persistSelectedProject();
    navigator.pushReplacementNamed(AppRoutes.projectForm);
  }
}

class AnomrMatrixGrid extends StatefulWidget {
  const AnomrMatrixGrid({
    super.key,
    required this.project,
    required this.isMobile,
  });

  final SavedProject project;
  final bool isMobile;

  @override
  State<AnomrMatrixGrid> createState() => _AnomrMatrixGridState();
}

class _AnomrMatrixGridState extends State<AnomrMatrixGrid> {
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;
  late List<PlutoColumnGroup> _columnGroups;
  PlutoGridStateManager? _stateManager;
  _ScrollCueState _scrollCues = const _ScrollCueState();

  static const double _scrollEpsilon = 1;

  /// Minimum width for read-only index columns before autofit runs.
  static const double _indexColumnMinWidth = 52;

  /// Default factor column width.
  static const double _factorColumnWidth = 120;

  /// Default range column width.
  static const double _rangeColumnWidth = 150;

  /// Matches [PlutoGridSettings.rowBorderWidth].
  static const double _rowBorderWidth = 1;

  double _columnTotalWidth() {
    final columns = _stateManager?.columns ?? _columns;
    return columns.fold<double>(0, (total, column) => total + column.width);
  }

  double _gridContentWidth({required bool includeVerticalScrollbar}) {
    final plutoTheme =
        Theme.of(context).extension<PlutoGridStyleTheme>() ??
        const PlutoGridStyleTheme.standard();
    final scrollbarWidth =
        includeVerticalScrollbar ? plutoTheme.scrollbarThickness : 0;
    return _columnTotalWidth() +
        PlutoGridSettings.gridInnerSpacing +
        scrollbarWidth;
  }

  double _gridContentHeight({
    required PlutoGridStyleTheme plutoTheme,
    required bool includeHorizontalScrollbar,
  }) {
    final scrollbarHeight =
        includeHorizontalScrollbar ? plutoTheme.scrollbarThickness : 0;
    final columnGroupHeight =
        _columnGroups.isEmpty ? 0 : plutoTheme.columnHeight;

    return PlutoGridSettings.gridInnerSpacing +
        columnGroupHeight +
        plutoTheme.columnHeight +
        (_rows.length * (plutoTheme.rowHeight + _rowBorderWidth)) +
        scrollbarHeight;
  }

  ({double width, double height, bool showScrollbars}) _displaySize({
    required double maxWidth,
    required double maxHeight,
    required PlutoGridStyleTheme plutoTheme,
  }) {
    final scrollbar = plutoTheme.scrollbarThickness;
    final contentWidth = _gridContentWidth(includeVerticalScrollbar: false);
    final contentHeight = _gridContentHeight(
      plutoTheme: plutoTheme,
      includeHorizontalScrollbar: false,
    );

    final overflowHeight = contentHeight > maxHeight;
    final overflowWidth = contentWidth > maxWidth;

    final width = overflowWidth
        ? maxWidth
        : contentWidth + (overflowHeight ? scrollbar : 0);
    final height = overflowHeight
        ? maxHeight
        : contentHeight + (overflowWidth ? scrollbar : 0);

    return (
      width: width,
      height: height,
      showScrollbars: overflowWidth || overflowHeight,
    );
  }

  void _handleGridResize() {
    if (mounted) {
      _updateScrollCues();
      setState(() {});
    }
  }

  void _handleScroll() {
    _updateScrollCues();
  }

  void _updateScrollCues() {
    final manager = _stateManager;
    if (manager == null || !mounted) return;

    final horizontalScroll = manager.scroll.bodyRowsHorizontal;
    final verticalScroll = manager.scroll.bodyRowsVertical;
    if (horizontalScroll?.hasClients != true ||
        verticalScroll?.hasClients != true) {
      return;
    }

    final maxHorizontal = horizontalScroll!.position.maxScrollExtent;
    final maxVertical = verticalScroll!.position.maxScrollExtent;
    final offsetHorizontal = horizontalScroll.offset;
    final offsetVertical = verticalScroll.offset;

    final hasHorizontalOverflow = maxHorizontal > _scrollEpsilon;
    final hasVerticalOverflow = maxVertical > _scrollEpsilon;

    final next = _ScrollCueState(
      showLeft: hasHorizontalOverflow && offsetHorizontal > _scrollEpsilon,
      showRight: hasHorizontalOverflow &&
          offsetHorizontal < maxHorizontal - _scrollEpsilon,
      showTop: hasVerticalOverflow && offsetVertical > _scrollEpsilon,
      showBottom:
          hasVerticalOverflow && offsetVertical < maxVertical - _scrollEpsilon,
    );

    if (next != _scrollCues) {
      setState(() => _scrollCues = next);
    }
  }

  void _detachScrollListeners() {
    _stateManager?.scroll.bodyRowsHorizontal?.removeListener(_handleScroll);
    _stateManager?.scroll.bodyRowsVertical?.removeListener(_handleScroll);
  }

  void _attachScrollListeners() {
    _detachScrollListeners();
    _stateManager?.scroll.bodyRowsHorizontal?.addListener(_handleScroll);
    _stateManager?.scroll.bodyRowsVertical?.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollCues();
    });
  }

  void _attachStateManager(PlutoGridStateManager manager) {
    _detachScrollListeners();
    _stateManager?.resizingChangeNotifier.removeListener(_handleGridResize);
    _stateManager = manager;
    _stateManager!.resizingChangeNotifier.addListener(_handleGridResize);
    _stateManager!.setSelectingMode(PlutoGridSelectingMode.cell);
    _attachScrollListeners();
  }

  Widget _buildPlutoGrid({
    required PlutoGridStyleTheme plutoTheme,
    required bool showScrollbars,
  }) {
    return PlutoGrid(
      columns: _columns,
      rows: _rows,
      columnGroups: _columnGroups,
      onChanged: _handleOnChanged,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        setState(() => _attachStateManager(event.stateManager));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fitIndexColumns();
        });
      },
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBorderColor: plutoTheme.borderColor,
          gridBorderRadius: plutoTheme.borderRadius,
          columnTextStyle: AppTextStyles.plutoColumn,
          enableColumnBorderVertical: true,
          rowHeight: plutoTheme.rowHeight,
          columnHeight: plutoTheme.columnHeight,
          gridBackgroundColor: plutoTheme.backgroundColor,
        ),
        scrollbar: PlutoGridScrollbarConfig(
          isAlwaysShown: showScrollbars,
          scrollbarThickness: plutoTheme.scrollbarThickness,
          scrollbarRadius: plutoTheme.scrollbarRadius,
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.none,
        ),
        shortcut: PlutoGridShortcut(
          actions: {
            ...PlutoGridShortcut.defaultActions,
            for (final modifier in [
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.control,
            ]) ...{
              LogicalKeySet(modifier, LogicalKeyboardKey.keyC):
                  const PlutoGridActionCopyValues(),
              LogicalKeySet(modifier, LogicalKeyboardKey.keyV):
                  const PlutoGridActionPasteValues(),
            },
          },
        ),
        enterKeyAction: PlutoGridEnterKeyAction.editingAndMoveDown,
        tabKeyAction: PlutoGridTabKeyAction.moveToNextOnEdge,
      ),
    );
  }

  double _bodyRowsTopInset(PlutoGridStyleTheme plutoTheme) {
    final manager = _stateManager;
    if (manager != null) {
      return manager.rowsTopOffset + PlutoGridSettings.gridBorderWidth;
    }

    final columnGroupHeight =
        _columnGroups.isEmpty ? 0 : plutoTheme.columnHeight;
    return PlutoGridSettings.gridInnerSpacing +
        columnGroupHeight +
        plutoTheme.columnHeight;
  }

  Widget _buildGridViewport({
    required double width,
    required double height,
    required PlutoGridStyleTheme plutoTheme,
    required bool showScrollbars,
    required ColorScheme scheme,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: _buildPlutoGrid(
              plutoTheme: plutoTheme,
              showScrollbars: showScrollbars,
            ),
          ),
          if (_scrollCues.showLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _GridScrollCue(
                edge: _ScrollCueEdge.left,
                scheme: scheme,
              ),
            ),
          if (_scrollCues.showRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _GridScrollCue(
                edge: _ScrollCueEdge.right,
                scheme: scheme,
              ),
            ),
          if (_scrollCues.showTop)
            Positioned(
              left: 0,
              right: 0,
              top: _bodyRowsTopInset(plutoTheme),
              child: _GridScrollCue(
                edge: _ScrollCueEdge.top,
                scheme: scheme,
              ),
            ),
          if (_scrollCues.showBottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _GridScrollCue(
                edge: _ScrollCueEdge.bottom,
                scheme: scheme,
              ),
            ),
        ],
      ),
    );
  }

  PlutoColumn _readOnlyIndexColumn({
    required String title,
    required String field,
    required int maxValue,
  }) {
    return PlutoColumn(
      title: title,
      field: field,
      type: PlutoColumnType.text(),
      readOnly: true,
      enableEditingMode: false,
      enableColumnDrag: false,
      enableContextMenu: false,
      enableDropToResize: false,
      width: _initialIndexColumnWidth(title: title, maxValue: maxValue),
      textAlign: PlutoColumnTextAlign.center,
      titleTextAlign: PlutoColumnTextAlign.center,
      renderer: (rendererContext) {
        final plutoTheme =
            Theme.of(context).extension<PlutoGridStyleTheme>() ??
            const PlutoGridStyleTheme.standard();
        return _readOnlyCell(
          rendererContext: rendererContext,
          plutoTheme: plutoTheme,
          alignment: Alignment.center,
          fadeOverflow: false,
        );
      },
    );
  }

  double _initialIndexColumnWidth({
    required String title,
    required int maxValue,
  }) {
    final titleWidth = _measureText(title, AppTextStyles.plutoColumn);
    final cellWidth = _measureText(
      maxValue.toString(),
      AppTextStyles.plutoColumn,
    );
    return (math.max(titleWidth, cellWidth) +
            AppSpacing.plutoFactorCell.horizontal +
            AppSpacing.lg)
        .clamp(_indexColumnMinWidth, double.infinity);
  }

  double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _fitIndexColumns() {
    final manager = _stateManager;
    if (manager == null || !mounted) return;

    var changed = false;
    for (final column in manager.columns) {
      if (column.field != 'row' && column.field != 'group') continue;

      final widthBefore = column.width;
      _autoFitReadOnlyColumn(column);
      if (column.width != widthBefore) changed = true;
    }

    if (changed) {
      setState(() {});
    }
  }

  void _autoFitReadOnlyColumn(PlutoColumn column) {
    final manager = _stateManager;
    if (manager == null) return;

    manager.autoFitColumn(context, column);

    final cellPadding =
        column.cellPadding ?? manager.configuration.style.defaultCellPadding;
    final minForTitle =
        _measureText(column.title, AppTextStyles.plutoColumn) +
        cellPadding.left +
        cellPadding.right +
        2;

    if (column.width < minForTitle) {
      manager.resizeColumn(column, minForTitle - column.width);
    }
  }

  Widget _readOnlyCell({
    required PlutoColumnRendererContext rendererContext,
    required PlutoGridStyleTheme plutoTheme,
    required Alignment alignment,
    bool fadeOverflow = true,
  }) {
    return Container(
      color: plutoTheme.factorCellBackground,
      alignment: alignment,
      padding: AppSpacing.plutoFactorCell,
      child: Text(
        rendererContext.cell.value?.toString() ?? '',
        style: AppTextStyles.plutoFactorCell(context),
        softWrap: false,
        maxLines: fadeOverflow ? 2 : 1,
        overflow: fadeOverflow ? TextOverflow.fade : TextOverflow.clip,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeGridData();
  }

  @override
  void dispose() {
    _detachScrollListeners();
    _stateManager?.resizingChangeNotifier.removeListener(_handleGridResize);
    super.dispose();
  }

  void _initializeGridData() {
    final formModel = context.read<ProjectFormModel>();
    final factors = formModel.factorDefinitions;
    final combinations = _generateCombinations(factors);
    final n = formModel.sampleSizeOption.rangesPerGroup.toInt();
    final totalSamples = formModel.sampleSizeOption.totalSamples;

    final factorFields = <String>[];

    // 1. Generate Columns
    _columns = [
      _readOnlyIndexColumn(
        title: 'Row',
        field: 'row',
        maxValue: totalSamples,
      ),
      _readOnlyIndexColumn(
        title: 'Replicate',
        field: 'group',
        maxValue: n,
      ),
      ...factors.asMap().entries.map((entry) {
        final idx = entry.key;
        final factor = entry.value;
        final field = 'factor_$idx';
        factorFields.add(field);
        return PlutoColumn(
          title: factor.name.trim().isEmpty ? 'Factor ${idx + 1}' : factor.name,
          field: field,
          type: PlutoColumnType.text(),
          enableEditingMode: false,
          enableColumnDrag: false,
          enableContextMenu: false,
          enableDropToResize: true,
          width: _factorColumnWidth,
          renderer: (rendererContext) {
            // Resolve the Pluto theme at render time (not initState) so we
            // don't violate the "no inherited lookups in initState" rule.
            final plutoTheme =
                Theme.of(context).extension<PlutoGridStyleTheme>() ??
                const PlutoGridStyleTheme.standard();
            return _readOnlyCell(
              rendererContext: rendererContext,
              plutoTheme: plutoTheme,
              alignment: Alignment.centerLeft,
            );
          },
        );
      }),
      PlutoColumn(
        title: 'Ranges',
        field: 'range',
        // Using text type to avoid any rounding/precision issues during paste.
        // The results view parses this back to double.
        type: PlutoColumnType.text(),
        readOnly: widget.isMobile,
        enableEditingMode: !widget.isMobile,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableDropToResize: true,
        width: _rangeColumnWidth,
        renderer: widget.isMobile ? _mobileRangeCellRenderer : null,
      ),
    ];

    // 2. Define Column Groups for Factors
    _columnGroups = [PlutoColumnGroup(title: 'Factors', fields: factorFields)];

    // 3. Generate Rows (Cartesian product repeated n times)
    _rows = [];
    for (int blockIdx = 0; blockIdx < n; blockIdx++) {
      for (int comboIdx = 0; comboIdx < combinations.length; comboIdx++) {
        final combo = combinations[comboIdx];
        final cells = <String, PlutoCell>{};

        for (int factorIdx = 0; factorIdx < factors.length; factorIdx++) {
          cells['factor_$factorIdx'] = PlutoCell(value: combo[factorIdx]);
        }

        // Use a consistent key for range value persistence
        final absoluteIdx = blockIdx * combinations.length + comboIdx;
        final savedValue = widget.project.matrixState['range_$absoluteIdx'];

        cells['group'] = PlutoCell(value: blockIdx + 1);
        cells['row'] = PlutoCell(value: absoluteIdx + 1);
        cells['range'] = PlutoCell(value: savedValue);
        _rows.add(PlutoRow(cells: cells));
      }
    }
  }

  List<List<String>> _generateCombinations(List<FactorDefinition> factors) {
    if (factors.isEmpty) return [[]];
    List<List<String>> results = [[]];
    for (final factor in factors) {
      final List<List<String>> nextResults = [];
      for (final res in results) {
        final s1 = factor.firstState.trim().isEmpty ? '1' : factor.firstState;
        final s2 = factor.secondState.trim().isEmpty ? '2' : factor.secondState;
        nextResults.add([...res, s1]);
        nextResults.add([...res, s2]);
      }
      results = nextResults;
    }
    return results;
  }

  Widget _mobileRangeCellRenderer(PlutoColumnRendererContext rendererContext) {
    final value = rendererContext.cell.value?.toString() ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openRangeEntrySheet(rendererContext),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: AppSpacing.plutoFactorCell,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ),
      ),
    );
  }

  Future<void> _openRangeEntrySheet(
    PlutoColumnRendererContext rendererContext,
  ) async {
    _stateManager?.setEditing(false);
    FocusManager.instance.primaryFocus?.unfocus();

    final formModel = context.read<ProjectFormModel>();
    final row = rendererContext.row;
    final factorStates = <FactorStateEntry>[
      for (var i = 0; i < formModel.factorDefinitions.length; i++)
        FactorStateEntry(
          factorName: _factorLabel(formModel.factorDefinitions[i], i),
          state: row.cells['factor_$i']?.value?.toString() ?? '',
        ),
    ];

    final result = await showRangeEntrySheet(
      context,
      entry: RangeEntryContext(
        rowIndex: _cellIntValue(row.cells['row']) ?? rendererContext.rowIdx + 1,
        replicateIndex:
            _cellIntValue(row.cells['group']) ?? rendererContext.rowIdx + 1,
        factorStates: factorStates,
        initialValue: rendererContext.cell.value?.toString(),
      ),
    );

    if (!mounted || result == null) return;

    _applyRangeValue(
      rowIdx: rendererContext.rowIdx,
      value: result.isEmpty ? null : result,
    );
  }

  int? _cellIntValue(PlutoCell? cell) {
    final value = cell?.value;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _factorLabel(FactorDefinition factor, int index) {
    final name = factor.name.trim();
    return name.isEmpty ? 'Factor ${index + 1}' : name;
  }

  void _applyRangeValue({required int rowIdx, required Object? value}) {
    final manager = _stateManager;
    if (manager == null) return;

    manager.rows[rowIdx].cells['range']!.value = value;
    widget.project.matrixState['range_$rowIdx'] = value;
    context.read<ProjectStore>().persistSelectedProject(markModified: true);

    final rangeColumn = manager.columns.firstWhere(
      (column) => column.field == 'range',
    );
    manager.autoFitColumn(context, rangeColumn);
    manager.notifyListeners();
    setState(() {});
  }

  void _handleOnChanged(PlutoGridOnChangedEvent event) {
    if (event.column.field == 'range') {
      _applyRangeValue(rowIdx: event.rowIdx, value: event.value);
    }
  }

  void _showResults(BuildContext context) {
    final manager = _stateManager;
    if (manager == null) return;

    if (!ProjectConfiguration.current.featureFlags.isEnabled(
          FeatureFlag.imputeMissingData,
        ) &&
        AnomrCalculator.hasMissingRangeData(manager)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ranges column data is incomplete. Please fill out all cells to continue.',
          ),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.anomrResults,
      arguments: manager,
    );
  }

  void _clearRanges() {
    if (_stateManager == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Clear All Ranges?'),
          content: const Text(
            'Are you sure you want to clear all entered range values? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  for (int i = 0; i < _stateManager!.rows.length; i++) {
                    _stateManager!.rows[i].cells['range']!.value = null;
                    widget.project.matrixState.remove('range_$i');
                  }
                  _stateManager!.notifyListeners();
                  context.read<ProjectStore>().persistSelectedProject(
                    markModified: true,
                  );
                });
                Navigator.pop(context);
              },
              child: Text('Clear All', style: TextStyle(color: scheme.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plutoTheme =
        Theme.of(context).extension<PlutoGridStyleTheme>() ??
        const PlutoGridStyleTheme.standard();
    final scheme = Theme.of(context).colorScheme;

    return AppLayoutBuilder(
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final displaySize = _displaySize(
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                      plutoTheme: plutoTheme,
                    );

                    return _buildGridViewport(
                      width: displaySize.width,
                      height: displaySize.height,
                      plutoTheme: plutoTheme,
                      showScrollbars: displaySize.showScrollbars,
                      scheme: scheme,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: layout.isMobile ? AppSpacing.md : AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppResponsiveActions(
                  layout: layout,
                  desktopAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _stateManager == null
                          ? null
                          : () => _showResults(context),
                      icon: const Icon(Icons.analytics),
                      label: const Text('Show Results'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _clearRanges,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All Ranges'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollCueState {
  const _ScrollCueState({
    this.showLeft = false,
    this.showRight = false,
    this.showTop = false,
    this.showBottom = false,
  });

  final bool showLeft;
  final bool showRight;
  final bool showTop;
  final bool showBottom;

  @override
  bool operator ==(Object other) {
    return other is _ScrollCueState &&
        showLeft == other.showLeft &&
        showRight == other.showRight &&
        showTop == other.showTop &&
        showBottom == other.showBottom;
  }

  @override
  int get hashCode => Object.hash(showLeft, showRight, showTop, showBottom);
}

enum _ScrollCueEdge { left, right, top, bottom }

class _GridScrollCue extends StatelessWidget {
  const _GridScrollCue({required this.edge, required this.scheme});

  final _ScrollCueEdge edge;
  final ColorScheme scheme;

  static const double _extent = 52;

  @override
  Widget build(BuildContext context) {
    final isHorizontal =
        edge == _ScrollCueEdge.left || edge == _ScrollCueEdge.right;

    return IgnorePointer(
      child: SizedBox(
        width: isHorizontal ? _extent : double.infinity,
        height: isHorizontal ? double.infinity : _extent,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: _gradient()),
          child: Align(
            alignment: _iconAlignment(),
            child: Padding(
              padding: _iconPadding(),
              child: Icon(
                _icon(),
                size: 22,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _gradient() {
    const fade = 0.96;
    const mid = 0.72;
    final surface = scheme.surface;
    final transparent = surface.withValues(alpha: 0);

    switch (edge) {
      case _ScrollCueEdge.left:
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            surface.withValues(alpha: fade),
            surface.withValues(alpha: mid),
            transparent,
          ],
          stops: const [0, 0.45, 1],
        );
      case _ScrollCueEdge.right:
        return LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            surface.withValues(alpha: fade),
            surface.withValues(alpha: mid),
            transparent,
          ],
          stops: const [0, 0.45, 1],
        );
      case _ScrollCueEdge.top:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            surface.withValues(alpha: fade),
            surface.withValues(alpha: mid),
            transparent,
          ],
          stops: const [0, 0.45, 1],
        );
      case _ScrollCueEdge.bottom:
        return LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            surface.withValues(alpha: fade),
            surface.withValues(alpha: mid),
            transparent,
          ],
          stops: const [0, 0.45, 1],
        );
    }
  }

  IconData _icon() {
    switch (edge) {
      case _ScrollCueEdge.left:
        return Icons.keyboard_double_arrow_left_rounded;
      case _ScrollCueEdge.right:
        return Icons.keyboard_double_arrow_right_rounded;
      case _ScrollCueEdge.top:
        return Icons.keyboard_double_arrow_up_rounded;
      case _ScrollCueEdge.bottom:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  Alignment _iconAlignment() {
    switch (edge) {
      case _ScrollCueEdge.left:
        return Alignment.centerLeft;
      case _ScrollCueEdge.right:
        return Alignment.centerRight;
      case _ScrollCueEdge.top:
        return Alignment.topCenter;
      case _ScrollCueEdge.bottom:
        return Alignment.bottomCenter;
    }
  }

  EdgeInsets _iconPadding() {
    switch (edge) {
      case _ScrollCueEdge.left:
        return const EdgeInsets.only(left: AppSpacing.sm);
      case _ScrollCueEdge.right:
        return const EdgeInsets.only(right: AppSpacing.sm);
      case _ScrollCueEdge.top:
        return const EdgeInsets.only(top: AppSpacing.sm);
      case _ScrollCueEdge.bottom:
        return const EdgeInsets.only(bottom: AppSpacing.sm);
    }
  }
}
