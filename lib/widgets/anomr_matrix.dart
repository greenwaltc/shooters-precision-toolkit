import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../navigation/app_routes.dart';
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analysis of Mean Ranges (ANOMR)',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8.0),
                  Text(formModel.experimentStructure.label),
                ],
              ),
            ),
            Expanded(
              child: AnomrMatrixGrid(
                key: ValueKey(
                    '${project.id}_${formModel.experimentStructure}_${formModel.sampleSizeOption.totalSamples}'),
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
          width: 120,
          renderer: (rendererContext) {
            return Container(
              color: Colors.grey[100],
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                rendererContext.cell.value?.toString() ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
        type: PlutoColumnType.number(),
        enableColumnDrag: false,
        enableContextMenu: false,
        width: 150,
      ),
    ];

    // 2. Define Column Groups for Factors
    _columnGroups = [
      PlutoColumnGroup(
        title: 'Factors',
        fields: factorFields,
      ),
    ];

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
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear All Ranges?'),
        content: const Text(
            'Are you sure you want to clear all entered range values? This action cannot be undone.'),
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
                context
                    .read<ProjectStore>()
                    .persistSelectedProject(markModified: true);
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // // Initial autofit for all columns to ensure data is visible and not wrapped
              // for (var column in _stateManager!.columns) {
              //   _stateManager!.autoFitColumn(context, column);
              // }
            },
            configuration: PlutoGridConfiguration(
              style: PlutoGridStyleConfig(
                gridBorderColor: Colors.grey[300]!,
                gridBorderRadius: BorderRadius.circular(8),
                columnTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                enableColumnBorderVertical: true,
                rowHeight: 48,
                columnHeight: 52,
                gridBackgroundColor: Colors.white,
              ),
              scrollbar: const PlutoGridScrollbarConfig(
                isAlwaysShown: true,
                scrollbarThickness: 8,
                scrollbarRadius: Radius.circular(10),
              ),
              columnSize: const PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _clearRanges,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Ranges'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
