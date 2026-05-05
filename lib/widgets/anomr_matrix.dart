import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../navigation/app_routes.dart';
import '../styles/theme_extensions/pluto_grid_theme.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';
import 'project_drawer.dart';

class AnomrMatrix extends StatelessWidget {
  const AnomrMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const _NoSelectedProjectPage();
    }

    return ChangeNotifierProvider<ProjectFormModel>.value(
      value: project.formModel,
      child: _AnomrMatrixScaffold(project: project),
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

    return Scaffold(
      drawer: const ProjectDrawer(),
      appBar: AppBar(
        title: Text(project.displayName),
        actions: [
          IconButton(
            tooltip: 'Project setup',
            onPressed: () => _goToProjectSetup(context, store),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis of Mean Ranges (ANOMR)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(formModel.experimentStructure.label),
                ],
              ),
            ),
            Expanded(
              child: AnomrMatrixGrid(
                key: ValueKey(
                  '${project.id}_${formModel.experimentStructure}_${formModel.sampleSizeOption.totalSamples}',
                ),
                project: project,
              ),
            ),
          ],
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

class AnomrMatrixGrid extends StatefulWidget {
  const AnomrMatrixGrid({super.key, required this.project});

  final SavedProject project;

  @override
  State<AnomrMatrixGrid> createState() => _AnomrMatrixGridState();
}

class _AnomrMatrixGridState extends State<AnomrMatrixGrid> {
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;
  late List<PlutoColumnGroup> _columnGroups;
  PlutoGridStateManager? _stateManager;

  /// Default factor column width.
  static const double _factorColumnWidth = 120;

  /// Default range column width.
  static const double _rangeColumnWidth = 150;

  @override
  void initState() {
    super.initState();
    _initializeGridData();
  }

  void _initializeGridData() {
    final formModel = context.read<ProjectFormModel>();
    final factors = formModel.factorDefinitions;
    final combinations = _generateCombinations(factors);
    final n = formModel.sampleSizeOption
        .rangesPerGroupFor(formModel.experimentStructure)
        .toInt();

    final factorFields = <String>[];

    // 1. Generate Columns
    _columns = [
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
            return Container(
              color: plutoTheme.factorCellBackground,
              alignment: Alignment.centerLeft,
              padding: AppSpacing.plutoFactorCell,
              child: Text(
                rendererContext.cell.value?.toString() ?? '',
                style: AppTextStyles.plutoFactorCell(context),
                softWrap: false,
                maxLines: 2,
                overflow: TextOverflow.fade,
              ),
            );
          },
        );
      }),
      PlutoColumn(
        title: 'Ranges',
        field: 'range',
        type: PlutoColumnType.number(
          format: '#.##########', // Support high precision decimals
        ),
        enableColumnDrag: false,
        enableContextMenu: false,
        width: _rangeColumnWidth,
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

  void _handleOnChanged(PlutoGridOnChangedEvent event) {
    if (event.column.field == 'range') {
      // Persist the range value to the project's matrix state
      widget.project.matrixState['range_${event.rowIdx}'] = event.value;

      // Mark the project as modified and save it
      context.read<ProjectStore>().persistSelectedProject(markModified: true);

      // Autofit the column on change to accommodate new data
      _stateManager?.autoFitColumn(context, event.column);
    }
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
    final plutoTheme = Theme.of(context).extension<PlutoGridStyleTheme>() ??
        const PlutoGridStyleTheme.standard();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: PlutoGrid(
            columns: _columns,
            rows: _rows,
            columnGroups: _columnGroups,
            onChanged: _handleOnChanged,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              _stateManager = event.stateManager;
              // Enable cell selection mode to support range copy/paste
              _stateManager?.setSelectingMode(PlutoGridSelectingMode.cell);
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
                isAlwaysShown: true,
                scrollbarThickness: plutoTheme.scrollbarThickness,
                scrollbarRadius: plutoTheme.scrollbarRadius,
              ),
              columnSize: const PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.none,
              ),
              // Excel-like navigation and selection
              shortcut: PlutoGridShortcut(
                actions: {
                  ...PlutoGridShortcut.defaultActions,
                  // Add Command shortcuts for macOS support
                  LogicalKeySet(
                    LogicalKeyboardKey.meta,
                    LogicalKeyboardKey.keyC,
                  ): const PlutoGridActionCopyValues(),
                  LogicalKeySet(
                    LogicalKeyboardKey.meta,
                    LogicalKeyboardKey.keyV,
                  ): const PlutoGridActionPasteValues(),
                },
              ),
              enterKeyAction: PlutoGridEnterKeyAction.editingAndMoveDown,
              tabKeyAction: PlutoGridTabKeyAction.moveToNextOnEdge,
            ),
          ),
        ),
        Padding(
          padding: AppSpacing.page,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.anomrResults,
                  arguments: _stateManager,
                ),
                icon: const Icon(Icons.analytics),
                label: const Text('Show Results'),
              ),
              OutlinedButton.icon(
                onPressed: _clearRanges,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Ranges'),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoSelectedProjectPage extends StatelessWidget {
  const _NoSelectedProjectPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANOMR Matrix')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.projects, (_) => false);
          },
          icon: const Icon(Icons.home_outlined),
          label: const Text('Projects'),
        ),
      ),
    );
  }
}
