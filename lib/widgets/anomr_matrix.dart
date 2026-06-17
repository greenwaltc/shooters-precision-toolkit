// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:async';
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
import '../styles/components/matrix_grid_style.dart';
import '../styles/components/scroll_cue_style.dart';
import '../styles/layout/app_layout.dart';
import '../styles/layout/app_viewport.dart';
import '../styles/theme_extensions/pluto_grid_theme.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';
import 'anomr_matrix/services/matrix_grid_clipboard.dart';
import 'anomr_matrix/services/matrix_grid_data_builder.dart';
import 'anomr_matrix/services/matrix_grid_history.dart';
import 'anomr_matrix/services/range_value_parser.dart';
import 'anomr_matrix/widgets/grid_scroll_cue.dart';
import 'anomr_results/services/anomr_calculator.dart';
import 'app_back_button.dart';
import 'app_copyright_footer.dart';
import 'no_selected_project_page.dart';
import 'project_drawer.dart';
import 'range_entry_sheet.dart';

/// Route that renders the selected project's ANOMR data-entry matrix.
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      builder: (context, layout) => Scaffold(
        drawer: const ProjectDrawer(),
        appBar: _buildAppBar(context, layout, store),
        body: _buildBody(context, layout, formModel),
        bottomNavigationBar: const AppCopyrightFooter(),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AppLayoutMetrics layout,
    ProjectStore store,
  ) {
    return AppBar(
      leading: AppBackButton(
        tooltip: 'Project setup',
        onPressed: () => _goToProjectSetup(context, store),
      ),
      title: Text(project.displayName),
      actions: [
        ...helpAppBarActionsFor(layout, preferAppBar: true),
        IconButton(
          tooltip: 'Project setup',
          onPressed: () => _goToProjectSetup(context, store),
          icon: const Icon(Icons.tune),
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLayoutMetrics layout,
    ProjectFormModel formModel,
  ) {
    return SafeArea(
      minimum: AppViewport.safeAreaMinimum,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MatrixHeader(layout: layout, formModel: formModel),
          Expanded(child: _buildGrid(layout, formModel)),
        ],
      ),
    );
  }

  Widget _buildGrid(AppLayoutMetrics layout, ProjectFormModel formModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.pageGutter),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.matrixHeaderMaxWidth),
          child: AnomrMatrixGrid(
            key: ValueKey(
              '${project.id}_${formModel.experimentStructure}_'
              '${formModel.sampleSizeOption.totalSamples}_${layout.isMobile}',
            ),
            project: project,
            isMobile: layout.isMobile,
          ),
        ),
      ),
    );
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

class _MatrixHeader extends StatelessWidget {
  const _MatrixHeader({required this.layout, required this.formModel});

  final AppLayoutMetrics layout;
  final ProjectFormModel formModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.pageGutter,
        layout.isMobile ? AppSpacing.sm : AppSpacing.md,
        layout.pageGutter,
        AppSpacing.lg,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.matrixHeaderMaxWidth),
          child: _buildTitle(context),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Factors and Ranges',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(formModel.experimentStructure.label),
      ],
    );
  }
}

/// Interactive Pluto grid used to enter range values for each factor state.
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

  bool _randomizeOrder = false;
  final math.Random _random = math.Random();
  bool _gridWasEditing = false;
  Timer? _rangeEditSelectionGuardTimer;
  VoidCallback? _rangeEditSelectionGuardListener;
  VoidCallback? _rangeEditSyncListener;
  final MatrixGridHistoryController _history = MatrixGridHistoryController();

  static const Duration _rangeEditSelectionGuardDuration =
      Duration(milliseconds: 150);

  static const double _scrollEpsilon = 1;

  void _handleRangeCellEditFocus() {
    final manager = _stateManager;
    if (manager == null) {
      return;
    }

    final isEditing = manager.isEditing == true;
    if (isEditing &&
        !_gridWasEditing &&
        manager.currentColumn?.field == 'range') {
      _beginRangeCellEditSelectionGuard();
      _attachRangeEditSyncListener();
    } else if (!isEditing && _gridWasEditing) {
      _endRangeCellEditSelectionGuard();
      _detachRangeEditSyncListener();
    }

    _gridWasEditing = isEditing;
  }

  void _beginRangeCellEditSelectionGuard() {
    _endRangeCellEditSelectionGuard();

    void enforceCaretAtEnd() {
      final manager = _stateManager;
      if (manager?.isEditing != true ||
          manager!.currentColumn?.field != 'range') {
        return;
      }

      final controller = manager.textEditingController;
      if (controller == null) {
        return;
      }

      final offset = controller.text.length;
      final selection = controller.selection;
      if (selection.baseOffset != offset || selection.extentOffset != offset) {
        controller.selection = TextSelection.collapsed(offset: offset);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        enforceCaretAtEnd();

        final controller = _stateManager?.textEditingController;
        if (controller == null) {
          return;
        }

        _rangeEditSelectionGuardListener = enforceCaretAtEnd;
        controller.addListener(enforceCaretAtEnd);

        _rangeEditSelectionGuardTimer = Timer(
          _rangeEditSelectionGuardDuration,
          _endRangeCellEditSelectionGuard,
        );
      });
    });
  }

  void _endRangeCellEditSelectionGuard() {
    _rangeEditSelectionGuardTimer?.cancel();
    _rangeEditSelectionGuardTimer = null;

    final controller = _stateManager?.textEditingController;
    final listener = _rangeEditSelectionGuardListener;
    if (controller != null && listener != null) {
      controller.removeListener(listener);
    }
    _rangeEditSelectionGuardListener = null;
  }

  /// Keeps the in-progress range edit synced to row/project state on every
  /// keystroke so validation and "Show Results" see the latest value without
  /// requiring Enter or an explicit blur.
  void _attachRangeEditSyncListener() {
    _detachRangeEditSyncListener();

    final controller = _stateManager?.textEditingController;
    if (controller == null) {
      return;
    }

    void syncOnKeystroke() {
      _syncActiveRangeEdit(
        recordHistory: false,
        showInvalidMessage: false,
        persist: false,
      );
    }

    _rangeEditSyncListener = syncOnKeystroke;
    controller.addListener(syncOnKeystroke);
    syncOnKeystroke();
  }

  void _detachRangeEditSyncListener() {
    final controller = _stateManager?.textEditingController;
    final listener = _rangeEditSyncListener;
    if (controller != null && listener != null) {
      controller.removeListener(listener);
    }
    _rangeEditSyncListener = null;
  }

  /// Commits the active range cell editor (if any) before navigation or
  /// validation.
  void _commitActiveRangeEdit() {
    final manager = _stateManager;
    if (manager == null ||
        manager.isEditing != true ||
        manager.currentColumn?.field != 'range') {
      return;
    }

    _syncActiveRangeEdit(
      recordHistory: true,
      showInvalidMessage: true,
      persist: true,
    );
    manager.setEditing(false);
  }

  /// Reads the active range editor and applies it to the grid model.
  void _syncActiveRangeEdit({
    required bool recordHistory,
    required bool showInvalidMessage,
    required bool persist,
  }) {
    final manager = _stateManager;
    if (manager == null ||
        manager.isEditing != true ||
        manager.currentColumn?.field != 'range') {
      return;
    }

    final rowIdx = manager.currentRowIdx;
    if (rowIdx == null) {
      return;
    }

    final controller = manager.textEditingController;
    if (controller == null) {
      return;
    }

    final parsed = RangeValueParser.parse(controller.text);
    if (parsed.invalid) {
      if (showInvalidMessage) {
        _showInvalidRangeValueMessage();
      }
      return;
    }

    _applyRangeValue(
      rowIdx: rowIdx,
      value: controller.text,
      recordHistory: recordHistory,
      persist: persist,
    );
  }

  PlutoGridStyleTheme _plutoTheme() {
    return Theme.of(context).extension<PlutoGridStyleTheme>() ??
        const PlutoGridStyleTheme.standard();
  }

  double _columnTotalWidth() {
    final columns = _stateManager?.columns ?? _columns;
    return columns.fold<double>(0, (total, column) => total + column.width);
  }

  double _gridContentWidth({required bool includeVerticalScrollbar}) {
    final plutoTheme = _plutoTheme();
    final scrollbarWidth = includeVerticalScrollbar
        ? plutoTheme.scrollbarThickness
        : 0;
    return _columnTotalWidth() +
        PlutoGridSettings.gridInnerSpacing +
        scrollbarWidth;
  }

  double _gridContentHeight({
    required PlutoGridStyleTheme plutoTheme,
    required bool includeHorizontalScrollbar,
  }) {
    final scrollbarHeight = includeHorizontalScrollbar
        ? plutoTheme.scrollbarThickness
        : 0;
    final columnGroupHeight = _columnGroups.isEmpty
        ? 0
        : plutoTheme.columnHeight;

    return PlutoGridSettings.gridInnerSpacing +
        columnGroupHeight +
        plutoTheme.columnHeight +
        (_rows.length *
            (plutoTheme.rowHeight + MatrixGridStyle.rowBorderWidth)) +
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
      showRight:
          hasHorizontalOverflow &&
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
    _stateManager?.removeListener(_handleRangeCellEditFocus);
    _endRangeCellEditSelectionGuard();
    _detachRangeEditSyncListener();
    _stateManager = manager;
    _stateManager!.resizingChangeNotifier.addListener(_handleGridResize);
    _stateManager!.setSelectingMode(PlutoGridSelectingMode.cell);
    _gridWasEditing = manager.isEditing == true;
    _stateManager!.addListener(_handleRangeCellEditFocus);
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
        shortcut: PlutoGridShortcut(actions: _shortcutActions()),
      ),
    );
  }

  /// Builds the grid's keyboard shortcut map.
  ///
  /// On desktop/web, Enter and Tab advance the active cell to the next range
  /// cell (Excel / Google Sheets convention). Because the range column is the
  /// only editable column, "next appropriate cell" is the range cell directly
  /// below (or above with Shift). Copy/paste and undo/redo use the platform
  /// modifier.
  Map<ShortcutActivator, PlutoGridShortcutAction> _shortcutActions() {
    return {
      ...PlutoGridShortcut.defaultActions,
      for (final modifier in [
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.control,
      ]) ...{
        LogicalKeySet(modifier, LogicalKeyboardKey.keyC):
            const MatrixGridCopyValuesAction(),
        LogicalKeySet(modifier, LogicalKeyboardKey.keyV):
            MatrixGridPasteValuesAction(history: _history),
      },
      if (!widget.isMobile) ...{
        LogicalKeySet(LogicalKeyboardKey.enter):
            const _AdvanceRangeCellAction(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter):
            const _AdvanceRangeCellAction(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
            const _AdvanceRangeCellAction(),
        LogicalKeySet(LogicalKeyboardKey.tab): const _AdvanceRangeCellAction(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
            const _AdvanceRangeCellAction(),
      },
    };
  }

  double _bodyRowsTopInset(PlutoGridStyleTheme plutoTheme) {
    final manager = _stateManager;
    if (manager != null) {
      return manager.rowsTopOffset + PlutoGridSettings.gridBorderWidth;
    }

    final columnGroupHeight = _columnGroups.isEmpty
        ? 0
        : plutoTheme.columnHeight;
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
              child: GridScrollCue(
                edge: ScrollCueEdge.left,
                scheme: scheme,
              ),
            ),
          if (_scrollCues.showRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GridScrollCue(
                edge: ScrollCueEdge.right,
                scheme: scheme,
              ),
            ),
          if (_scrollCues.showTop)
            Positioned(
              left: 0,
              right: 0,
              top: _bodyRowsTopInset(plutoTheme),
              child: GridScrollCue(
                edge: ScrollCueEdge.top,
                scheme: scheme,
              ),
            ),
          if (_scrollCues.showBottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GridScrollCue(
                edge: ScrollCueEdge.bottom,
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
      renderer: (rendererContext) => _readOnlyCell(
        rendererContext: rendererContext,
        plutoTheme: _plutoTheme(),
        alignment: Alignment.center,
        fadeOverflow: false,
      ),
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
        .clamp(MatrixGridStyle.indexColumnMinWidth, double.infinity);
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
    HardwareKeyboard.instance.addHandler(_matrixKeyboardHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_matrixKeyboardHandler);
    _detachScrollListeners();
    _stateManager?.resizingChangeNotifier.removeListener(_handleGridResize);
    _stateManager?.removeListener(_handleRangeCellEditFocus);
    _endRangeCellEditSelectionGuard();
    _detachRangeEditSyncListener();
    super.dispose();
  }

  void _initializeGridData() {
    _history.clear();
    final formModel = context.read<ProjectFormModel>();
    final gridData = MatrixGridDataBuilder.build(
      formModel: formModel,
      project: widget.project,
    );

    _randomizeOrder = widget.project.randomizeOrder;
    final ordered = _initialRowOrder(gridData.rows);
    _renumberRunOrder(ordered);

    _rows = ordered;
    _columns = _buildColumns(formModel, gridData.totalSamples);
    _columnGroups = _buildColumnGroups(formModel);
  }

  /// Resolves the row order for the first paint, honoring any persisted
  /// randomized sequence so the layout survives navigation and app restarts.
  List<PlutoRow> _initialRowOrder(List<PlutoRow> rows) {
    if (!_randomizeOrder) return rows;

    final sequence = widget.project.randomizeSequence;
    if (sequence != null && _sequenceMatchesRows(sequence, rows)) {
      return _applySequence(rows, sequence);
    }

    // Randomization is on but no usable sequence is stored (e.g. the sample
    // size changed). Generate one now and persist it after the first frame.
    final shuffled = [...rows]..shuffle(_random);
    widget.project.randomizeSequence = shuffled.map(_storageIndexOf).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectStore>().persistSelectedProject();
    });
    return shuffled;
  }

  List<PlutoColumn> _buildColumns(
    ProjectFormModel formModel,
    int totalSamples,
  ) {
    final isOneFactor =
        formModel.experimentStructure == ExperimentStructure.simpleABComparison;

    return [
      _readOnlyIndexColumn(
        title: 'Run Order',
        field: 'row',
        maxValue: totalSamples,
      ),
      // One-factor designs collapse to a single state per row, so the
      // replicate index is meaningless and the column is omitted.
      if (!isOneFactor)
        _readOnlyIndexColumn(
          title: 'Replicate',
          field: 'group',
          maxValue: formModel.sampleSizeOption.rangesPerGroup.toInt(),
        ),
      ..._buildFactorColumns(formModel),
      _buildRangeColumn(),
    ];
  }

  List<PlutoColumn> _buildFactorColumns(ProjectFormModel formModel) {
    return [
      for (final entry in formModel.factorDefinitions.asMap().entries)
        _buildFactorColumn(index: entry.key, factor: entry.value),
    ];
  }

  PlutoColumn _buildFactorColumn({
    required int index,
    required FactorDefinition factor,
  }) {
    return PlutoColumn(
      title: MatrixGridDataBuilder.factorLabel(factor, index),
      field: 'factor_$index',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      enableColumnDrag: false,
      enableContextMenu: false,
      enableDropToResize: true,
      width: MatrixGridStyle.factorColumnWidth,
      renderer: (rendererContext) => _readOnlyCell(
        rendererContext: rendererContext,
        plutoTheme: _plutoTheme(),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  PlutoColumn _buildRangeColumn() {
    return PlutoColumn(
      title: 'Ranges',
      field: 'range',
      // Text avoids precision loss during paste; results parse back to double.
      type: PlutoColumnType.text(),
      readOnly: widget.isMobile,
      enableEditingMode: !widget.isMobile,
      enableColumnDrag: false,
      enableContextMenu: false,
      enableDropToResize: true,
      width: MatrixGridStyle.rangeColumnWidth,
      renderer: widget.isMobile ? _mobileRangeCellRenderer : null,
    );
  }

  List<PlutoColumnGroup> _buildColumnGroups(ProjectFormModel formModel) {
    return [
      PlutoColumnGroup(
        title: 'Factors',
        fields: [
          for (
            var index = 0;
            index < formModel.factorDefinitions.length;
            index++
          )
            'factor_$index',
        ],
      ),
    ];
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
          factorName: MatrixGridDataBuilder.factorLabel(
            formModel.factorDefinitions[i],
            i,
          ),
          state: row.cells['factor_$i']?.value?.toString() ?? '',
        ),
    ];

    final result = await showRangeEntrySheet(
      context,
      entry: RangeEntryContext(
        rowIndex:
            MatrixGridDataBuilder.cellIntValue(row.cells['row']) ??
            rendererContext.rowIdx + 1,
        replicateIndex:
            MatrixGridDataBuilder.cellIntValue(row.cells['group']) ??
            rendererContext.rowIdx + 1,
        factorStates: factorStates,
        initialValue: rendererContext.cell.value?.toString(),
        showReplicate:
            formModel.experimentStructure !=
            ExperimentStructure.simpleABComparison,
      ),
    );

    if (!mounted || result == null) return;

    _applyRangeValue(rowIdx: rendererContext.rowIdx, value: result);
  }

  void _applyRangeValueForHistory(
    int rowIdx,
    Object? value, {
    bool recordHistory = true,
  }) {
    _applyRangeValue(
      rowIdx: rowIdx,
      value: value,
      recordHistory: recordHistory,
    );
  }

  // TODO: Undo/redo keybindings — see TODO in matrix_grid_history.dart.
  bool _matrixKeyboardHandler(KeyEvent event) {
    if (!mounted) {
      return false;
    }

    final isUndo = isMatrixUndoShortcut(event);
    final isRedo = isMatrixRedoShortcut(event);
    if (!isUndo && !isRedo) {
      return false;
    }

    // While the user is actively typing into a cell (uncommitted edits), let
    // Flutter's built-in EditableText undo/redo handle the keystroke so the
    // in-cell text history works. We must not consume the event in that case.
    if (matrixUndoShouldDeferToTextField(_stateManager)) {
      return false;
    }

    final handled = isUndo
        ? performMatrixGridUndo(
            history: _history,
            stateManager: _stateManager,
            applyRangeValue: _applyRangeValueForHistory,
          )
        : performMatrixGridRedo(
            history: _history,
            stateManager: _stateManager,
            applyRangeValue: _applyRangeValueForHistory,
          );

    if (handled && mounted) {
      setState(() {});
    }

    return handled;
  }

  void _applyRangeValue({
    required int rowIdx,
    required Object? value,
    bool recordHistory = true,
    bool persist = true,
  }) {
    final manager = _stateManager;
    if (manager == null) return;

    final previousValue = manager.rows[rowIdx].cells['range']!.value?.toString();

    final parsed = RangeValueParser.parse(value);
    if (parsed.invalid) {
      if (persist || recordHistory) {
        _showInvalidRangeValueMessage();
      }
    }

    final normalizedValue = parsed.displayValue;
    if (normalizedValue == previousValue) {
      return;
    }

    if (recordHistory) {
      _history.record(
        MatrixRangeChange(
          rowIdx: rowIdx,
          previousValue: previousValue,
          newValue: normalizedValue,
        ),
      );
    }

    manager.rows[rowIdx].cells['range']!.value = normalizedValue;
    widget.project.matrixState[MatrixGridDataBuilder.storageKeyForRow(
      manager.rows[rowIdx],
    )] = normalizedValue;
    if (persist) {
      context.read<ProjectStore>().persistSelectedProject(markModified: true);
    }

    manager.notifyListeners();
    setState(() {});
  }

  void _showInvalidRangeValueMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(RangeValueParser.invalidInputMessage)),
    );
  }

  void _handleOnChanged(PlutoGridOnChangedEvent event) {
    if (event.column.field == 'range') {
      _applyRangeValue(rowIdx: event.rowIdx, value: event.value);
    }
  }

  void _showResults(BuildContext context) {
    _commitActiveRangeEdit();

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

    Navigator.pushNamed(context, AppRoutes.anomrResults, arguments: manager);
  }

  void _clearRanges() {
    if (_stateManager == null) return;

    showDialog(context: context, builder: _buildClearRangesDialog);
  }

  AlertDialog _buildClearRangesDialog(BuildContext context) {
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
          onPressed: () => _confirmClearRanges(context),
          child: Text('Clear All', style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }

  void _confirmClearRanges(BuildContext dialogContext) {
    setState(_clearAllRangeValues);
    Navigator.pop(dialogContext);
  }

  void _clearAllRangeValues() {
    final manager = _stateManager;
    if (manager == null) return;

    _history.beginBatch();
    try {
      for (var rowIdx = 0; rowIdx < manager.rows.length; rowIdx += 1) {
        final row = manager.rows[rowIdx];
        final previousValue = row.cells['range']!.value?.toString();
        if (previousValue == null) {
          continue;
        }
        _applyRangeValue(rowIdx: rowIdx, value: null);
      }
    } finally {
      _history.endBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plutoTheme = _plutoTheme();
    final scheme = Theme.of(context).colorScheme;

    return AppLayoutBuilder(
      builder: (context, layout) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RandomizeOrderToggle(
            value: _randomizeOrder,
            onChanged: _stateManager == null ? null : _onRandomizeToggled,
          ),
          Expanded(child: _buildGridArea(plutoTheme, scheme)),
          _MatrixActions(
            layout: layout,
            canShowResults: _stateManager != null,
            onShowResults: () => _showResults(context),
            onClearRanges: _clearRanges,
          ),
        ],
      ),
    );
  }

  /// Toggling on generates a fresh randomized order; toggling off restores the
  /// canonical sequential order. Either way the new state is persisted so it
  /// survives navigation, project switches, and app restarts. Rows are
  /// reordered by instance, so range values stay bound to their rows.
  void _onRandomizeToggled(bool value) {
    final manager = _stateManager;
    if (manager == null) return;

    _history.clear();

    setState(() => _randomizeOrder = value);

    final current = manager.refRows.toList();
    final ordered = value
        ? ([...current]..shuffle(_random))
        : ([...current]
            ..sort((a, b) => _storageIndexOf(a).compareTo(_storageIndexOf(b))));

    _persistRandomizeState(value, ordered);
    _applyOrderedRows(manager, ordered);
  }

  void _persistRandomizeState(bool value, List<PlutoRow> ordered) {
    widget.project.randomizeOrder = value;
    widget.project.randomizeSequence = value
        ? ordered.map(_storageIndexOf).toList()
        : null;
    context.read<ProjectStore>().persistSelectedProject();
  }

  void _applyOrderedRows(PlutoGridStateManager manager, List<PlutoRow> ordered) {
    _renumberRunOrder(ordered);

    _rows = ordered;
    manager.removeAllRows(notify: false);
    manager.appendRows(ordered);
    manager.notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollCues();
    });
  }

  void _renumberRunOrder(List<PlutoRow> rows) {
    for (var index = 0; index < rows.length; index++) {
      rows[index].cells['row']!.value = index + 1;
    }
  }

  int _storageIndexOf(PlutoRow row) {
    return MatrixGridDataBuilder.cellIntValue(row.cells['storage']) ?? 0;
  }

  bool _sequenceMatchesRows(List<int> sequence, List<PlutoRow> rows) {
    if (sequence.length != rows.length) return false;
    final rowIndices = rows.map(_storageIndexOf).toSet();
    final sequenceIndices = sequence.toSet();
    return sequenceIndices.length == rowIndices.length &&
        sequenceIndices.containsAll(rowIndices);
  }

  List<PlutoRow> _applySequence(List<PlutoRow> rows, List<int> sequence) {
    final rowsByStorage = {
      for (final row in rows) _storageIndexOf(row): row,
    };
    return [for (final index in sequence) rowsByStorage[index]!];
  }

  Widget _buildGridArea(PlutoGridStyleTheme plutoTheme, ColorScheme scheme) {
    return Align(
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
    );
  }
}

class _RandomizeOrderToggle extends StatelessWidget {
  const _RandomizeOrderToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Randomize order?', style: textTheme.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Text(value ? 'Yes' : 'No', style: textTheme.labelLarge),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MatrixActions extends StatelessWidget {
  const _MatrixActions({
    required this.layout,
    required this.canShowResults,
    required this.onShowResults,
    required this.onClearRanges,
  });

  final AppLayoutMetrics layout;
  final bool canShowResults;
  final VoidCallback onShowResults;
  final VoidCallback onClearRanges;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: layout.isMobile ? AppSpacing.md : AppSpacing.lg,
        // Desktop/web place the action row above the page bottom; add
        // breathing room so the buttons aren't cramped against the edge.
        bottom: layout.isMobile ? 0 : AppSpacing.xl,
      ),
      child: SizedBox(
        width: double.infinity,
        child: AppResponsiveActions(
          layout: layout,
          desktopAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: canShowResults ? onShowResults : null,
              icon: const Icon(Icons.analytics),
              label: const Text('Show Results'),
            ),
            OutlinedButton.icon(
              onPressed: onClearRanges,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Ranges'),
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moves the active cell to the next range cell for spreadsheet-style data
/// entry. Plain Enter/Tab move down; Shift+Enter/Shift+Tab move up. Committing
/// any in-progress edit happens implicitly when the current cell changes.
class _AdvanceRangeCellAction extends PlutoGridShortcutAction {
  const _AdvanceRangeCellAction();

  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    if (stateManager.currentCell == null) {
      stateManager.setCurrentCell(stateManager.firstCell, 0);
      return;
    }

    final moveUp = HardwareKeyboard.instance.isShiftPressed;
    stateManager.moveCurrentCell(
      moveUp ? PlutoMoveDirection.up : PlutoMoveDirection.down,
      notify: false,
    );

    if (stateManager.currentColumn?.enableEditingMode == true) {
      stateManager.setEditing(true, notify: false);
    }

    stateManager.notifyListeners();
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
