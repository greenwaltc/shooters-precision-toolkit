import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../../../../shared/foundation/behavior_policy.dart';
import '../../../../shared/foundation/clipboard_events.dart';
import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/app_bar_actions.dart';
import '../../../../shared/ui/app_brand_bar.dart';
import '../../../../shared/ui/app_copyright_footer.dart';
import '../../../../shared/ui/app_nav_chrome.dart';
import '../../../../shared/ui/navigation/app_routes.dart';
import '../../../../shared/ui/product_configuration.dart';
import '../../../../shared/ui/scroll_cue.dart';
import '../../../../shared/ui/theme/app_design.dart';
import '../../../../shared/ui/theme/components/matrix_grid_style.dart';
import '../../../../shared/ui/theme/components/scroll_cue_style.dart';
import '../../../../shared/ui/theme/layout/app_layout.dart';
import '../../../../shared/ui/theme/theme_extensions/pluto_grid_theme.dart';
import '../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../../../../shared/ui/theme/tokens/app_text_styles.dart';
import '../../domain/range_value_parser.dart';
import '../project_file_transfer.dart';
import '../project_store.dart';
import '../results/services/anomr_calculator.dart';
import '../saved_project.dart';
import '../test_design/project_form_model.dart';
import '../widgets/no_selected_project_page.dart';
import '../widgets/project_editing_notice.dart';
import '../widgets/project_save_status.dart';
import 'services/matrix_grid_clipboard.dart';
import 'services/matrix_grid_data_builder.dart';
import 'services/matrix_grid_history.dart';
import 'widgets/matrix_replicate_dividers.dart';
import 'widgets/mobile_range_cell.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Route that renders the selected project's ANOMR data-entry matrix.
class AnomrMatrix extends StatelessWidget {
  /// Creates the matrix page for the project selected in the workspace.
  const AnomrMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return NoSelectedProjectPage(title: AppCopy.english.dataMatrix);
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
      if (!mounted) {
        return;
      }
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
    final hasLeading = AppNavChrome.canPop(context);
    final titleSpacing = AppBrandAssets.projectTitleSpacing(
      layout,
      hasLeading: hasLeading,
    );
    final actionItems = [
      AppBarActionBar.instructions(context),
      AppBarActionBar.contact(context),
      AppBarActionBar.donations(context),
      AppNavChrome.homeActionItem(
        context: context,
        persistSelection: store.persistSelectedProject,
      ),
      AppBarActionItem(
        label: AppCopy.english.testDesign,
        icon: Icons.tune,
        tooltip: AppCopy.english.testDesign,
        onPressed: () => _goToProjectSetup(context, store),
      ),
      ...AppBarActionBar.signOutActions(context),
    ];
    final actionsMetrics = AppBarActionsMetrics.of(
      context,
      layout: layout,
      items: actionItems,
      hasLeading: hasLeading,
      titleSpacing: titleSpacing,
      hasTitleStatus: true,
    );
    final titleMetrics = AppBrandTitleMetrics.of(
      context,
      label: project.displayName,
      titleMaxWidth: actionsMetrics.titleMaxWidth,
    );

    return AppBar(
      toolbarHeight: titleMetrics.toolbarHeight,
      titleSpacing: titleSpacing,
      automaticallyImplyLeading: false,
      leading: AppNavChrome.backLeading(context),
      title: AppBrandTitle(
        label: project.displayName,
        metrics: titleMetrics,
        trailing: ProjectSaveStatus(inBanner: true, compact: layout.isMobile),
      ),
      actions: AppBarActionBar.build(
        context,
        layout: layout,
        items: actionItems,
        hasLeading: hasLeading,
        titleSpacing: titleSpacing,
        hasTitleStatus: true,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLayoutMetrics layout,
    ProjectFormModel formModel,
  ) {
    // Bottom inset is owned by [AppCopyrightFooter]; padding here used to leave
    // a dead band under the action buttons when OS text size was large.
    return SafeArea(
      bottom: false,
      child: _buildGrid(context, layout, formModel),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    AppLayoutMetrics layout,
    ProjectFormModel formModel,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isMobile ? layout.pageGutter : 24,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.matrixHeaderMaxWidth),
          child: AnomrMatrixGrid(
            key: ValueKey(
              '${project.id}_${formModel.experimentStructure}_'
              '${formModel.sampleSizeOption.totalSamples}_${layout.isMobile}_'
              '${Theme.of(context).brightness.name}',
            ),
            project: project,
            isMobile: layout.isMobile,
            keyboardVisible:
                layout.isMobile && MediaQuery.viewInsetsOf(context).bottom > 0,
            canEdit: context.read<ProjectStore>().canEditProject(project.id),
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
    if (!context.mounted) {
      return;
    }
    await AppRoutes.openProjectFormFromMatrix(navigator);
  }
}

class _MatrixHeader extends StatelessWidget {
  const _MatrixHeader({
    required this.mobile,
    required this.formModel,
    required this.trailing,
  });

  final bool mobile;
  final ProjectFormModel formModel;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  AppCopy.english.dataMatrixMessage,
                  style: textTheme.titleLarge,
                ),
              ),
              Expanded(flex: 6, child: trailing),
            ],
          ),
          Text(
            mobile
                ? AppCopy.english.factorRunCount(
                    formModel.experimentStructure.factorCount,
                    formModel.sampleSizeOption.totalSamples,
                  )
                : formModel.experimentStructure.label,
            style: mobile ? textTheme.bodySmall : textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Interactive Pluto grid used to enter range values for each factor state.
class AnomrMatrixGrid extends StatefulWidget {
  /// Creates a measurement grid for [project].
  ///
  /// [isMobile] selects the compact interaction and layout. Set [canEdit]
  /// to false to keep browsing and copying available during a handoff.
  /// [keyboardVisible] enables the focused mobile editing layout.
  const AnomrMatrixGrid({
    super.key,
    required this.project,
    required this.isMobile,
    this.keyboardVisible = false,
    this.canEdit = true,
  });

  final SavedProject project;
  final bool isMobile;
  final bool keyboardVisible;
  final bool canEdit;

  @override
  State<AnomrMatrixGrid> createState() => _AnomrMatrixGridState();
}

class _AnomrMatrixGridState extends State<AnomrMatrixGrid> {
  // initState builds all columns/rows together before build or callbacks run.
  // Every built row has range/storage/index cells; these SDK cells remain
  // mutable, while nullable selection/focus state must be checked separately.
  static const double _desktopMaxWidth = 1180;
  static const _mobileTitlePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
  );
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;
  List<double>? _mobileContentWidths;
  late List<int> _defaultRunSequence;
  late List<PlutoColumnGroup> _columnGroups;
  PlutoGridStateManager? _stateManager;
  final _scrollCues = ValueNotifier(const _ScrollCueState());

  bool _randomizeOrder = false;
  bool _exportingProject = false;
  late final math.Random _random = context.read<math.Random>();
  bool _gridWasEditing = false;
  Timer? _rangeEditSelectionGuardTimer;
  VoidCallback? _rangeEditSelectionGuardListener;
  VoidCallback? _rangeEditSyncListener;
  final MatrixGridHistoryController _history = MatrixGridHistoryController();
  VoidCallback? _removeBrowserClipboard;
  int? _requestedRange;
  late final ProjectStore _store;
  bool _isInTree = true;

  bool get _canWrite => _isInTree && _store.canEditProject(widget.project.id);

  static const Duration _rangeEditSelectionGuardDuration =
      BehaviorPolicy.selectionGuard;

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
      // Pluto mounts its text controller when the editing cell is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            identical(manager, _stateManager) &&
            manager.isEditing &&
            manager.currentColumn?.field == 'range') {
          _attachRangeEditSyncListener();
        }
      });
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
  /// keystroke so validation and "Results" see the latest value without
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
    final theme =
        Theme.of(context).extension<PlutoGridStyleTheme>() ??
        const PlutoGridStyleTheme.standard();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return theme.copyWith(
      rowHeight: (widget.isMobile ? 48 : 36) * textScale,
      columnHeight: 40 * textScale,
    );
  }

  double _columnTotalWidth() {
    final columns = _stateManager?.columns ?? _columns;
    return columns.fold<double>(0, (total, column) => total + column.width);
  }

  // Pluto paints the grid border without reserving horizontal layout space.
  double get _gridHorizontalInset => widget.isMobile
      ? PlutoGridSettings.gridPadding * 2
      : PlutoGridSettings.gridInnerSpacing;

  double _gridContentWidth({required bool includeVerticalScrollbar}) {
    final plutoTheme = _plutoTheme();
    final scrollbarWidth = includeVerticalScrollbar
        ? plutoTheme.scrollbarThickness
        : 0;
    return _columnTotalWidth() + _gridHorizontalInset + scrollbarWidth;
  }

  double _gridContentHeight({
    required PlutoGridStyleTheme plutoTheme,
    required bool includeHorizontalScrollbar,
  }) {
    final scrollbarHeight = includeHorizontalScrollbar
        ? plutoTheme.scrollbarThickness
        : 0;
    final columnGroupHeight = widget.isMobile || _columnGroups.isEmpty
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

    final width = math.min(maxWidth, _desktopMaxWidth);
    final height = overflowHeight
        ? maxHeight
        : contentHeight + (overflowWidth ? scrollbar : 0);

    return (
      width: width,
      height: height,
      showScrollbars: overflowWidth || overflowHeight,
    );
  }

  bool _gridUpdateScheduled = false;
  bool _pendingGridResize = false;

  void _handleGridResize() => _scheduleGridUpdate(resize: true);

  void _handleScroll() => _scheduleGridUpdate();

  /// Combines grid notifications into one update after layout finishes.
  ///
  /// Column sizing can trigger scroll and resize events during layout. Waiting
  /// until the frame ends lets the scroll hints use the final measurements.
  void _scheduleGridUpdate({bool resize = false}) {
    _pendingGridResize = _pendingGridResize || resize;
    if (_gridUpdateScheduled) {
      return;
    }
    _gridUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gridUpdateScheduled = false;
      if (!mounted) {
        return;
      }
      final resized = _pendingGridResize;
      _pendingGridResize = false;
      _updateScrollCues();
      if (resized) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _updateScrollCues() {
    final manager = _stateManager;
    if (manager == null || !mounted) {
      return;
    }

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

    _scrollCues.value = next;
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
      if (mounted) {
        _updateScrollCues();
      }
    });
  }

  void _attachStateManager(PlutoGridStateManager manager) {
    _detachStateManager();
    _stateManager = manager;
    _stateManager!.resizingChangeNotifier.addListener(_handleGridResize);
    _stateManager!.setSelectingMode(PlutoGridSelectingMode.cell);
    _gridWasEditing = manager.isEditing == true;
    _stateManager!.addListener(_handleRangeCellEditFocus);
    if (widget.isMobile) {
      manager.gridFocusNode.addListener(_handleMobileEditorFocusChanged);
    }
    _attachScrollListeners();
  }

  void _detachStateManager() {
    _detachScrollListeners();
    _stateManager?.resizingChangeNotifier.removeListener(_handleGridResize);
    _stateManager?.removeListener(_handleRangeCellEditFocus);
    _stateManager?.gridFocusNode.removeListener(
      _handleMobileEditorFocusChanged,
    );
    _endRangeCellEditSelectionGuard();
    _detachRangeEditSyncListener();
    _stateManager = null;
  }

  void _handleMobileEditorFocusChanged() {
    setState(() {});
  }

  PlutoGridStyleConfig _plutoStyleConfig(PlutoGridStyleTheme plutoTheme) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark
        ? const PlutoGridStyleConfig.dark()
        : const PlutoGridStyleConfig();

    return base.copyWith(
      gridBorderColor: plutoTheme.borderColor,
      gridBorderRadius: plutoTheme.borderRadius,
      borderColor: plutoTheme.borderColor,
      columnTextStyle: AppTextStyles.plutoColumn.copyWith(
        color: scheme.onSurface,
      ),
      defaultColumnTitlePadding: widget.isMobile ? _mobileTitlePadding : null,
      cellTextStyle: TextStyle(color: scheme.onSurface, fontSize: 14),
      rowHeight: plutoTheme.rowHeight,
      columnHeight: plutoTheme.columnHeight,
      gridBackgroundColor: plutoTheme.backgroundColor,
      rowColor: plutoTheme.backgroundColor,
      cellColorInEditState: plutoTheme.backgroundColor,
      cellColorInReadOnlyState: plutoTheme.factorCellBackground,
    );
  }

  Widget _buildPlutoGrid({
    required PlutoGridStyleTheme plutoTheme,
    required bool showScrollbars,
  }) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => _isBrowserClipboardKey(event)
          ? KeyEventResult.skipRemainingHandlers
          : KeyEventResult.ignored,
      child: PlutoGrid(
        key: ObjectKey(_columns),
        columns: _columns,
        rows: _rows,
        columnGroups: widget.isMobile ? const [] : _columnGroups,
        onChanged: _handleOnChanged,
        onLoaded: (PlutoGridOnLoadedEvent event) {
          setState(() => _attachStateManager(event.stateManager));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (!widget.isMobile) {
              _fitIndexColumns();
            }
            _revealRequestedRange();
          });
        },
        configuration: PlutoGridConfiguration(
          style: _plutoStyleConfig(plutoTheme),
          scrollbar: PlutoGridScrollbarConfig(
            isAlwaysShown: showScrollbars,
            scrollbarThickness: plutoTheme.scrollbarThickness,
            scrollbarRadius: plutoTheme.scrollbarRadius,
          ),
          columnSize: PlutoGridColumnSizeConfig(
            autoSizeMode: widget.isMobile
                ? PlutoAutoSizeMode.none
                : PlutoAutoSizeMode.scale,
          ),
          shortcut: PlutoGridShortcut(actions: _shortcutActions()),
        ),
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
    final enter = widget.canEdit
        ? const _AdvanceRangeCellAction()
        : _AdvanceRangeCellAction(
            requestEditing: (row) =>
                unawaited(_editRangeHere(_storageIndexOf(row))),
          );
    return {
      ...PlutoGridShortcut.defaultActions,
      for (final modifier in [
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.control,
      ]) ...{
        LogicalKeySet(modifier, LogicalKeyboardKey.keyC):
            const MatrixGridCopyValuesAction(),
        LogicalKeySet(modifier, LogicalKeyboardKey.keyV): _pasteAction(),
      },
      if (!widget.isMobile || !widget.canEdit) ...{
        LogicalKeySet(LogicalKeyboardKey.enter): enter,
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): enter,
      },
      if (!widget.isMobile) ...{
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

    final columnGroupHeight = widget.isMobile || _columnGroups.isEmpty
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
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  // The grid's two scrolling axes are nested. Deeper
                  // notifications may come from an inline text editor.
                  if (notification.depth <= 1) {
                    _scheduleGridUpdate();
                  }
                  return false;
                },
                child: _buildPlutoGrid(
                  plutoTheme: plutoTheme,
                  showScrollbars: showScrollbars,
                ),
              ),
            ),
          ),
          if (_stateManager case final manager?)
            Positioned.fill(
              child: MatrixReplicateDividers(
                manager: manager,
                showRowBoundaries: !_randomizeOrder,
                showColumnGroups: !widget.isMobile,
              ),
            ),
          if (!_hasMobileEditorFocus)
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: _scrollCues,
                builder: (context, cues, _) => Stack(
                  children: [
                    if (cues.showLeft)
                      const Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: ScrollCue(edge: ScrollCueEdge.left),
                      ),
                    if (cues.showRight)
                      const Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: ScrollCue(edge: ScrollCueEdge.right),
                      ),
                    if (cues.showTop)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _bodyRowsTopInset(plutoTheme),
                        child: const ScrollCue(edge: ScrollCueEdge.top),
                      ),
                    if (cues.showBottom)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ScrollCue(edge: ScrollCueEdge.bottom),
                      ),
                  ],
                ),
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
      suppressedAutoSize: true,
      cellPadding: widget.isMobile ? EdgeInsets.zero : null,
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
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Fits mobile columns to the widest rendered label or value. Spare width
  /// fills the viewport; a wider matrix keeps its readable widths and scrolls.
  void _fitMobileColumns(double viewportWidth, BuildContext context) {
    final contentWidths = _mobileContentWidths ??= _measureMobileColumns(
      context,
    );
    final available = viewportWidth - _gridHorizontalInset;
    final contentWidth = contentWidths.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    final extra = math.max(0.0, available - contentWidth) / _columns.length;
    var changed = false;
    for (var i = 0; i < _columns.length; i++) {
      final width = contentWidths[i] + extra;
      if (_columns[i].width != width) {
        _columns[i].width = width;
        changed = true;
      }
    }
    final manager = _stateManager;
    if (changed && manager != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(manager, _stateManager)) {
          manager.notifyResizingListeners();
        }
      });
    }
  }

  List<double> _measureMobileColumns(BuildContext context) {
    final defaults = DefaultTextStyle.of(context).style;
    final headerStyle = defaults.merge(AppTextStyles.plutoColumn);
    final factorStyle = defaults.merge(AppTextStyles.plutoFactorCell(context));
    final rangeStyle = defaults.merge(Theme.of(context).textTheme.bodyMedium);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    double widthOf(String text, TextStyle style) => TextPainter.computeWidth(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
    );

    return _columns.map((column) {
      final style = column.field == 'range' ? rangeStyle : factorStyle;
      final values = {
        for (final row in _rows)
          row.cells[column.field]?.value?.toString() ?? '',
      };
      var width =
          widthOf(column.title, headerStyle) + _mobileTitlePadding.horizontal;
      for (final value in values) {
        width = math.max(width, widthOf(value, style) + 2 * AppSpacing.md);
      }
      return width.ceilToDouble() + PlutoGridSettings.gridBorderWidth * 2;
    }).toList();
  }

  void _fitIndexColumns() {
    final manager = _stateManager;
    if (manager == null || !mounted) {
      return;
    }

    var changed = false;
    for (final column in manager.columns) {
      if (column.field != 'row' && column.field != 'group') {
        continue;
      }

      final widthBefore = column.width;
      _autoFitReadOnlyColumn(column);
      if (column.width != widthBefore) {
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
    }
  }

  void _autoFitReadOnlyColumn(PlutoColumn column) {
    final manager = _stateManager;
    if (manager == null) {
      return;
    }

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
    return _mouseSelectionCell(
      rendererContext,
      ListenableBuilder(
        listenable: rendererContext.stateManager,
        // Pluto caches renderer children between selection changes.
        builder: (context, child) {
          final manager = rendererContext.stateManager;
          final selected = manager.isSelectedCell(
            rendererContext.cell,
            rendererContext.column,
            rendererContext.rowIdx,
          );
          return Container(
            color: selected
                ? manager.style.activatedColor
                : plutoTheme.factorCellBackground,
            alignment: alignment,
            padding: widget.isMobile
                ? const EdgeInsets.symmetric(horizontal: AppSpacing.md)
                : AppSpacing.plutoFactorCell,
            child: child,
          );
        },
        child: Text(
          rendererContext.cell.value?.toString() ?? '',
          style: AppTextStyles.plutoFactorCell(context),
          softWrap: false,
          maxLines: fadeOverflow ? 2 : 1,
          overflow: fadeOverflow ? TextOverflow.fade : TextOverflow.clip,
        ),
      ),
    );
  }

  /// Mouse drags select immediately; touch keeps its scrolling/entry behavior.
  Widget _mouseSelectionCell(PlutoColumnRendererContext cell, Widget child) {
    return GestureDetector(
      key: ValueKey('matrix-cell-${cell.rowIdx}-${cell.column.field}'),
      behavior: HitTestBehavior.opaque,
      supportedDevices: const {PointerDeviceKind.mouse},
      onPanStart: (details) {
        final manager = cell.stateManager;
        _commitActiveRangeEdit();
        manager.setEditing(false);
        manager.setCurrentCell(cell.cell, cell.rowIdx);
        manager.setCurrentSelectingPosition(cellPosition: null);
        manager.setKeepFocus(true);
        manager.gridFocusNode.requestFocus();
        manager.setSelecting(true);
        manager.setCurrentSelectingPositionWithOffset(details.globalPosition);
      },
      onPanUpdate: (details) {
        cell.stateManager.setCurrentSelectingPositionWithOffset(
          details.globalPosition,
        );
        cell.stateManager.eventManager!.addEvent(
          PlutoGridScrollUpdateEvent(offset: details.globalPosition),
        );
      },
      onPanEnd: (_) => _endMouseSelection(cell.stateManager),
      onPanCancel: () => _endMouseSelection(cell.stateManager),
      child: child,
    );
  }

  void _endMouseSelection(PlutoGridStateManager manager) {
    manager.setSelecting(false);
    PlutoGridScrollUpdateEvent.stopScroll(
      manager,
      PlutoGridScrollUpdateDirection.all,
    );
  }

  bool get _acceptsGridClipboard =>
      mounted &&
      _stateManager?.hasFocus == true &&
      !_hasMobileEditorFocus &&
      ModalRoute.of(context)?.isCurrent == true;

  bool get _hasMobileEditorFocus {
    final focus = _stateManager?.gridFocusNode;
    return widget.isMobile &&
        focus != null &&
        focus.hasFocus &&
        !focus.hasPrimaryFocus;
  }

  MatrixGridPasteValuesAction _pasteAction() => MatrixGridPasteValuesAction(
    history: _history,
    canApply: () => _acceptsGridClipboard && _canWrite,
    onRejected: _showPasteRestriction,
  );

  void _showPasteRestriction() {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            MatrixGridClipboard.pasteRestrictionMessage,
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          backgroundColor: scheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: BehaviorPolicy.pasteErrorVisibility,
        ),
      );
  }

  bool _isBrowserClipboardKey(KeyEvent event) {
    if (!kIsWeb || !_acceptsGridClipboard || event is KeyUpEvent) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    return (keyboard.isMetaPressed || keyboard.isControlPressed) &&
        !keyboard.isAltPressed &&
        (event.logicalKey == LogicalKeyboardKey.keyV ||
            (event.logicalKey == LogicalKeyboardKey.keyC &&
                _stateManager?.isEditing != true));
  }

  KeyEventResult _clipboardKeyHandler(KeyEvent event) {
    if (!_acceptsGridClipboard) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (!(keyboard.isMetaPressed || keyboard.isControlPressed) ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final paste = event.logicalKey == LogicalKeyboardKey.keyV;
    if (_isBrowserClipboardKey(event)) {
      // Pluto normally consumes every key. Skip its handler, then the enclosing
      // Focus returns this clipboard keystroke to the browser. Returning skip
      // from an early handler alone still walks the focus tree in Flutter 3.41.
      _stateManager!.keyManager!.eventResult.skip(KeyEventResult.ignored);
      return KeyEventResult.ignored;
    }
    if (!kIsWeb && paste) {
      if (event is KeyDownEvent) {
        _pasteAction().pasteFromClipboard(_stateManager!);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    _store = context.read<ProjectStore>();
    _initializeGridData();
    HardwareKeyboard.instance.addHandler(_matrixKeyboardHandler);
    FocusManager.instance.addEarlyKeyEventHandler(_clipboardKeyHandler);
    _removeBrowserClipboard = context.read<ClipboardEvents>().register(
      acceptsPaste: () => _acceptsGridClipboard && _canWrite,
      copyText: () => _acceptsGridClipboard && _stateManager?.isEditing != true
          ? MatrixGridClipboard.copyTextForSelection(_stateManager!)
          : null,
      pasteText: (text) => _pasteAction().applyText(_stateManager!, text),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mobileContentWidths = null;
  }

  @override
  void deactivate() {
    // Pluto can report an edit while disposing its TextField.
    _isInTree = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isInTree = true;
  }

  @override
  void didUpdateWidget(AnomrMatrixGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // PlutoGrid keeps its own mutable rows and editors. Remount it when the
    // store replaces the cloud model or revokes this session's editing access.
    if (oldWidget.project != widget.project ||
        oldWidget.canEdit != widget.canEdit) {
      _detachStateManager();
      _initializeGridData();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_matrixKeyboardHandler);
    FocusManager.instance.removeEarlyKeyEventHandler(_clipboardKeyHandler);
    _removeBrowserClipboard?.call();
    _detachStateManager();
    _scrollCues.dispose();
    super.dispose();
  }

  void _initializeGridData() {
    _history.clear();
    _mobileContentWidths = null;
    final formModel = widget.project.formModel;
    final gridData = MatrixGridDataBuilder.build(
      formModel: formModel,
      project: widget.project,
    );

    _randomizeOrder = widget.project.randomizeOrder;
    _defaultRunSequence = gridData.rows.map(_storageIndexOf).toList();
    final ordered = _initialRowOrder(List.of(gridData.rows));
    _renumberRunOrder(ordered);

    final factorColumns = _buildFactorColumns(formModel);
    _rows = ordered;
    _columns = _buildColumns(formModel, gridData.totalSamples, factorColumns);
    _columnGroups = [
      PlutoColumnGroup(
        title: AppCopy.english.factors,
        fields: [for (final column in factorColumns) column.field],
      ),
    ];
  }

  /// Resolves the row order for the first paint, honoring any persisted
  /// randomized sequence so the layout survives navigation and app restarts.
  List<PlutoRow> _initialRowOrder(List<PlutoRow> rows) {
    if (!_randomizeOrder) {
      return rows;
    }

    final sequence = widget.project.randomizeSequence;
    if (sequence != null && _sequenceMatchesRows(sequence, rows)) {
      return _applySequence(rows, sequence);
    }

    // Randomization is on but no usable sequence is stored (e.g. the sample
    // size changed). Generate one now and persist it after the first frame.
    final shuffled = [...rows]..shuffle(_random);
    widget.project.randomizeSequence = shuffled.map(_storageIndexOf).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProjectStore>().markProjectChanged(widget.project.id);
      }
    });
    return shuffled;
  }

  List<PlutoColumn> _buildColumns(
    ProjectFormModel formModel,
    int totalSamples,
    List<PlutoColumn> factorColumns,
  ) {
    final isOneFactor =
        formModel.experimentStructure == ExperimentStructure.simpleABComparison;

    return [
      _readOnlyIndexColumn(
        title: AppCopy.english.runOrder,
        field: 'row',
        maxValue: totalSamples,
      ),
      // One-factor designs collapse to a single state per row, so the
      // replicate index is meaningless and the column is omitted.
      if (!isOneFactor)
        _readOnlyIndexColumn(
          title: AppCopy.english.replicate,
          field: 'group',
          maxValue: formModel.sampleSizeOption.rangesPerGroup.toInt(),
        ),
      ...factorColumns,
      _buildRangeColumn(),
    ];
  }

  List<PlutoColumn> _buildFactorColumns(ProjectFormModel formModel) {
    final factors = formModel.factorDefinitions;
    return [
      for (var index = 0; index < factors.length; index++)
        _buildFactorColumn(index: index, factor: factors[index]),
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
      enableDropToResize: !widget.isMobile,
      cellPadding: widget.isMobile ? EdgeInsets.zero : null,
      width: MatrixGridStyle.factorColumnWidth,
      renderer: (rendererContext) => _readOnlyCell(
        rendererContext: rendererContext,
        plutoTheme: _plutoTheme(),
        alignment: AlignmentDirectional.centerStart.resolve(
          Directionality.of(context),
        ),
      ),
    );
  }

  PlutoColumn _buildRangeColumn() {
    return PlutoColumn(
      title: AppCopy.english.groupSize,
      field: 'range',
      // Text avoids precision loss during paste; results parse back to double.
      type: PlutoColumnType.text(),
      readOnly: widget.isMobile || !widget.canEdit,
      enableEditingMode: !widget.isMobile && widget.canEdit,
      cellPadding: widget.isMobile ? EdgeInsets.zero : null,
      enableColumnDrag: false,
      enableContextMenu: false,
      enableDropToResize: !widget.isMobile,
      width: MatrixGridStyle.rangeColumnWidth,
      renderer: (cell) => _mouseSelectionCell(
        cell,
        widget.isMobile && widget.canEdit
            ? MobileRangeCell(
                key: GlobalObjectKey<MobileRangeCellState>(cell.cell),
                keyboardVisible: widget.keyboardVisible,
                onNext: cell.rowIdx + 1 < cell.stateManager.rows.length
                    ? () => _focusMobileRange(cell.rowIdx + 1)
                    : null,
                onPrevious: cell.rowIdx > 0
                    ? () => _focusMobileRange(cell.rowIdx - 1)
                    : null,
                value: cell.cell.value?.toString() ?? '',
                onFocused: () {
                  cell.stateManager.setKeepFocus(true, notify: false);
                  cell.stateManager.setCurrentCell(cell.cell, cell.rowIdx);
                },
                onChanged: (text) {
                  if (!RangeValueParser.parse(text).invalid) {
                    _applyRangeValue(rowIdx: cell.rowIdx, value: text);
                  }
                },
                finishEditing: (text) {
                  if (RangeValueParser.parse(text).invalid) {
                    _showInvalidRangeValueMessage();
                  }
                  return cell.cell.value?.toString() ?? '';
                },
              )
            : _displayRangeCell(cell),
      ),
    );
  }

  void _focusMobileRange(int index) {
    final manager = _stateManager;
    if (manager == null ||
        !_canWrite ||
        index < 0 ||
        index >= manager.rows.length) {
      return;
    }
    final cell = manager.rows[index].cells['range']!;
    final key = GlobalObjectKey<MobileRangeCellState>(cell);
    if (key.currentState case final editor?) {
      editor.requestFocus();
      return;
    }
    manager.moveScrollByRow(
      index < (manager.currentRowIdx ?? 0)
          ? PlutoMoveDirection.up
          : PlutoMoveDirection.down,
      index,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(manager, _stateManager) && _canWrite) {
        key.currentState?.requestFocus();
      }
    });
  }

  Widget _displayRangeCell(PlutoColumnRendererContext cell) {
    final value = SizedBox.expand(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: widget.isMobile
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.md)
              : EdgeInsets.zero,
          child: Text(
            cell.cell.value?.toString() ?? '',
            style: widget.isMobile
                ? Theme.of(context).textTheme.bodyMedium
                : cell.stateManager.configuration.style.cellTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    if (widget.canEdit) {
      return value;
    }
    return Semantics(
      label: context.l10n.groupSize,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _editRangeHere(_storageIndexOf(cell.row)),
        child: value,
      ),
    );
  }

  Future<void> _editRangeHere(int storageIndex) async {
    final claimed = await ProjectEditingNotice.request(
      context,
      widget.project.id,
      allowTakeover: true,
    );
    if (claimed && mounted) {
      _requestedRange = storageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _revealRequestedRange();
        }
      });
    }
  }

  void _revealRequestedRange() {
    final storageIndex = _requestedRange;
    final manager = _stateManager;
    if (storageIndex == null ||
        manager == null ||
        !widget.canEdit ||
        !_canWrite) {
      return;
    }
    _requestedRange = null;
    final row = manager.rows.indexWhere(
      (row) => _storageIndexOf(row) == storageIndex,
    );
    if (row < 0) {
      return;
    }
    manager.moveScrollByRow(PlutoMoveDirection.down, row);
    final rangeColumn = manager.columnIndexesByShowFrozen.indexWhere(
      (index) => manager.refColumns[index].field == 'range',
    );
    if (rangeColumn > 0) {
      manager.moveScrollByColumn(PlutoMoveDirection.right, rangeColumn - 1);
    }
    manager.setCurrentCell(manager.rows[row].cells['range'], row);
    // A browser may require a fresh touch gesture to open its soft keyboard.
    if (!widget.isMobile) {
      manager.setKeepFocus(true);
      manager.gridFocusNode.requestFocus();
      manager.setEditing(true);
    }
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

  // TODO: Repair undo/redo keybindings; tracking: docs/reference/code_maintenance.md#matrix-undo-and-redo.
  bool _matrixKeyboardHandler(KeyEvent event) {
    if (!mounted || !_canWrite) {
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
    if (_hasMobileEditorFocus ||
        matrixUndoShouldDeferToTextField(_stateManager)) {
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
    Object? previousValueOverride,
    bool recordHistory = true,
    bool persist = true,
  }) {
    final manager = _stateManager;
    if (manager == null || !_canWrite) {
      return;
    }

    final row = manager.rows[rowIdx];
    final cell = row.cells['range']!;
    final storageKey = MatrixGridDataBuilder.storageKeyForRow(row);
    final cellValue = cell.value?.toString();
    final storedValue = widget.project.matrixState[storageKey];

    final parsed = RangeValueParser.parse(value);
    if (parsed.invalid) {
      if (persist || recordHistory) {
        _showInvalidRangeValueMessage();
      }
    }

    final normalizedValue = parsed.displayValue;
    final displayText = normalizedValue ?? '';
    final cellMatches = cell.value == displayText;
    final storeMatches = _rangeValuesEqual(
      storedValue?.toString(),
      normalizedValue,
    );

    // PlutoGrid writes the cell *before* invoking onChanged. Skipping when the
    // cell already matches would leave matrixState stale even though the grid
    // looks correct — so always sync storage when it differs.
    if (cellMatches && storeMatches) {
      return;
    }

    if (recordHistory) {
      final historyPrevious = RangeValueParser.parse(
        previousValueOverride ?? storedValue ?? cellValue,
      ).displayValue;
      if (!_rangeValuesEqual(historyPrevious, normalizedValue)) {
        _history.record(
          MatrixRangeChange(
            rowIdx: rowIdx,
            previousValue: historyPrevious,
            newValue: normalizedValue,
          ),
        );
      }
    }

    if (!cellMatches) {
      cell.value = displayText;
    }
    widget.project.matrixState[storageKey] = normalizedValue;
    _store.markProjectChanged(widget.project.id);

    if (!cellMatches) {
      manager.notifyListeners();
    }
    if (!cellMatches || widget.isMobile) {
      _mobileContentWidths = null;
      setState(() {});
    }
  }

  /// Copies every visible Group Size cell into [SavedProject.matrixState].
  ///
  /// Used before leaving the matrix so persistence cannot miss cells that only
  /// lived in the PlutoGrid model.
  void _flushAllRangeValuesToProject({bool persist = true}) {
    final manager = _stateManager;
    if (manager == null || !_canWrite) {
      return;
    }

    final changed = MatrixGridDataBuilder.syncMatrixStateFromGrid(
      project: widget.project,
      manager: manager,
    );

    if (changed && persist && mounted) {
      context.read<ProjectStore>().markProjectChanged(widget.project.id);
    }
  }

  static bool _rangeValuesEqual(String? a, String? b) {
    final left = (a == null || a.isEmpty) ? null : a;
    final right = (b == null || b.isEmpty) ? null : b;
    return left == right;
  }

  void _showInvalidRangeValueMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppCopy.english.groupSizeValuesMustBeNumbersPleaseCorrect,
        ),
      ),
    );
  }

  void _handleOnChanged(PlutoGridOnChangedEvent event) {
    if (_canWrite &&
        event.column.field == 'range' &&
        _columns.contains(event.column)) {
      _applyRangeValue(
        rowIdx: event.rowIdx,
        value: event.value,
        previousValueOverride: event.oldValue,
      );
    }
  }

  Future<void> _exportProject() async {
    if (_exportingProject) return;
    final transfer = context.read<ProjectFileTransfer>();
    final l10n = context.l10n;
    setState(() => _exportingProject = true);
    try {
      _commitActiveRangeEdit();
      _flushAllRangeValuesToProject();
      final destination = await transfer.exportProject(
        widget.project,
        l10n.exportProjectTitle,
      );
      if (mounted && destination != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.projectExportSuccess)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.projectExportFailure)));
      }
    } finally {
      if (mounted) setState(() => _exportingProject = false);
    }
  }

  void _showResults(BuildContext context) {
    _commitActiveRangeEdit();
    _flushAllRangeValuesToProject();

    final manager = _stateManager;
    if (manager == null) {
      return;
    }

    if (!ProjectConfigurationScope.of(
          context,
        ).featureFlags.isEnabled(FeatureFlag.imputeMissingData) &&
        AnomrCalculator.hasMissingRangeData(manager)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppCopy.english.groupSizeColumnDataIsIncompletePleaseFill,
          ),
        ),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.anomrResults, arguments: manager);
  }

  Future<void> _clearRanges() async {
    if (_stateManager == null) {
      return;
    }

    await showDialog<void>(context: context, builder: _buildClearRangesDialog);
  }

  AlertDialog _buildClearRangesDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(AppCopy.english.clearGroupSizes),
      content: Text(AppCopy.english.areYouSureYouWantToClearAll),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppCopy.english.cancel),
        ),
        TextButton(
          onPressed: () => _confirmClearRanges(context),
          child: Text(
            AppCopy.english.clear,
            style: TextStyle(color: scheme.error),
          ),
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
    if (manager == null || !_canWrite) {
      return;
    }

    _history.beginBatch();
    try {
      for (var rowIdx = 0; rowIdx < manager.rows.length; rowIdx += 1) {
        final row = manager.rows[rowIdx];
        final previousValue = row.cells['range']!.value?.toString() ?? '';
        if (previousValue.isEmpty) {
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
    final focusMode = widget.keyboardVisible && _hasMobileEditorFocus;

    final desktop =
        AppLayoutMetrics.of(context).isDesktop &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final actions = _MatrixActions(
      compact: !desktop,
      onShowResults: _stateManager == null ? null : () => _showResults(context),
      onExportProject: _stateManager == null || _exportingProject
          ? null
          : _exportProject,
      onClearRanges: widget.canEdit ? _clearRanges : null,
    );
    final randomizeOrder = _RandomizeOrderToggle(
      value: _randomizeOrder,
      onChanged: _stateManager == null || !widget.canEdit
          ? null
          : _onRandomizeToggled,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppCopy.english.dataMatrixMessage,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.project.formModel.experimentStructure.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                randomizeOrder,
                const SizedBox(width: AppSpacing.lg),
                actions,
              ],
            ),
          ),
        if (!desktop && !focusMode) ...[
          _MatrixHeader(
            mobile: widget.isMobile,
            formModel: widget.project.formModel,
            trailing: randomizeOrder,
          ),
          actions,
        ],
        ProjectEditingNotice(projectId: widget.project.id),
        Expanded(child: _buildGridArea(plutoTheme)),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final browsingMinHeight =
            (widget.isMobile
                ? 280 + 140 * (scale - 1).clamp(0, double.infinity)
                : AppDesign.matrixMinBodyHeight) *
            scale;
        // At very short heights, keep at least a column header and a full
        // editable row in the grid. The outer scroll view can reveal that row.
        final minHeight = focusMode
            ? _bodyRowsTopInset(plutoTheme) +
                  plutoTheme.rowHeight +
                  MatrixGridStyle.rowBorderWidth
            : browsingMinHeight;
        final viewport = !widget.isMobile && constraints.maxHeight >= minHeight
            ? content
            : SingleChildScrollView(
                child: SizedBox(
                  height: math.max(minHeight, constraints.maxHeight),
                  child: content,
                ),
              );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _desktopMaxWidth),
            child: viewport,
          ),
        );
      },
    );
  }

  /// Toggling on generates a fresh randomized order; toggling off restores the
  /// default run order. Either way the new state is persisted so it
  /// survives navigation, project switches, and app restarts. Rows are
  /// reordered by instance, so range values stay bound to their rows.
  void _onRandomizeToggled(bool value) {
    final manager = _stateManager;
    if (manager == null || !_canWrite) {
      return;
    }

    _history.clear();

    setState(() => _randomizeOrder = value);

    final current = manager.refRows.toList();
    final ordered = value
        ? ([...current]..shuffle(_random))
        : _applySequence(current, _defaultRunSequence);

    _persistRandomizeState(value, ordered);
    _applyOrderedRows(manager, ordered);
  }

  void _persistRandomizeState(bool value, List<PlutoRow> ordered) {
    widget.project.randomizeOrder = value;
    widget.project.randomizeSequence = value
        ? ordered.map(_storageIndexOf).toList()
        : null;
    context.read<ProjectStore>().markProjectChanged(widget.project.id);
  }

  void _applyOrderedRows(
    PlutoGridStateManager manager,
    List<PlutoRow> ordered,
  ) {
    _renumberRunOrder(ordered);

    _rows = ordered;
    manager.removeAllRows(notify: false);
    manager.appendRows(ordered);
    manager.notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateScrollCues();
      }
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
    if (sequence.length != rows.length) {
      return false;
    }
    final rowIndices = rows.map(_storageIndexOf).toSet();
    final sequenceIndices = sequence.toSet();
    return sequenceIndices.length == rowIndices.length &&
        sequenceIndices.containsAll(rowIndices);
  }

  List<PlutoRow> _applySequence(List<PlutoRow> rows, List<int> sequence) {
    final rowsByStorage = {for (final row in rows) _storageIndexOf(row): row};
    return [for (final index in sequence) rowsByStorage[index]!];
  }

  Widget _buildGridArea(PlutoGridStyleTheme plutoTheme) {
    return Align(
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (widget.isMobile) {
            _fitMobileColumns(
              math.min(constraints.maxWidth, _desktopMaxWidth),
              context,
            );
          }
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    spacing: AppSpacing.md,
    children: [
      Flexible(
        child: Text(
          AppCopy.english.randomizeOrder,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.end,
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

ButtonStyle _clearButtonStyle(ColorScheme scheme) => OutlinedButton.styleFrom(
  foregroundColor: scheme.error,
  side: BorderSide(color: scheme.error),
);

class _MatrixActions extends StatelessWidget {
  const _MatrixActions({
    required this.compact,
    required this.onShowResults,
    required this.onExportProject,
    required this.onClearRanges,
  });

  final bool compact;
  final VoidCallback? onShowResults;
  final VoidCallback? onExportProject;
  final VoidCallback? onClearRanges;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final clearStyle = _clearButtonStyle(Theme.of(context).colorScheme);
    if (!compact) {
      return Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          OutlinedButton.icon(
            onPressed: onClearRanges,
            icon: const Icon(Icons.clear_all),
            label: Text(l10n.clear),
            style: clearStyle,
          ),
          Tooltip(
            message: l10n.exportProjectTitle,
            child: OutlinedButton.icon(
              onPressed: onExportProject,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.export),
            ),
          ),
          FilledButton.icon(
            onPressed: onShowResults,
            icon: const Icon(Icons.analytics),
            label: Text(l10n.results),
          ),
        ],
      );
    }

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(0, kMinInteractiveDimension),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: IntrinsicHeight(
        child: Row(
          spacing: AppSpacing.md,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClearRanges,
                style: clearStyle.merge(style),
                child: Text(l10n.clear, textAlign: TextAlign.center),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: l10n.exportProjectTitle,
                child: OutlinedButton(
                  onPressed: onExportProject,
                  style: style,
                  child: Text(l10n.export, textAlign: TextAlign.center),
                ),
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: onShowResults,
                style: style,
                child: Text(l10n.results, textAlign: TextAlign.center),
              ),
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
  const _AdvanceRangeCellAction({this.requestEditing});

  final ValueChanged<PlutoRow>? requestEditing;

  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    if (stateManager.currentCell == null) {
      stateManager.setCurrentCell(stateManager.firstCell, 0);
      return;
    }
    final row = stateManager.currentRow;
    if (row != null &&
        stateManager.currentColumn?.field == 'range' &&
        requestEditing != null) {
      requestEditing!(row);
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
