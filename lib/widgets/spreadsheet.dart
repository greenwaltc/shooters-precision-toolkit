import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'My Sample Text')
Widget newSpreadsheet() {
  return const Spreadsheet();
}

class Spreadsheet extends StatelessWidget {
  const Spreadsheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlutoGridExamplePage();
  }
}

/// PlutoGrid Example
//
/// For more examples, go to the demo web link on the github below.
class PlutoGridExamplePage extends StatefulWidget {
  const PlutoGridExamplePage({super.key});

  @override
  State<PlutoGridExamplePage> createState() => _PlutoGridExamplePageState();
}

class _PlutoGridExamplePageState extends State<PlutoGridExamplePage> {
  final List<PlutoColumn> columns = <PlutoColumn>[
    PlutoColumn(title: 'Id', field: 'id', type: PlutoColumnType.text()),
    PlutoColumn(title: 'Name', field: 'name', type: PlutoColumnType.text()),
    PlutoColumn(title: 'Age', field: 'age', type: PlutoColumnType.number()),
    PlutoColumn(
      title: 'Role',
      field: 'role',
      type: PlutoColumnType.select(<String>['Programmer', 'Designer', 'Owner']),
    ),
    PlutoColumn(title: 'Joined', field: 'joined', type: PlutoColumnType.date()),
    PlutoColumn(
      title: 'Working time',
      field: 'working_time',
      type: PlutoColumnType.time(),
    ),
    PlutoColumn(
      title: 'salary',
      field: 'salary',
      type: PlutoColumnType.currency(),
      footerRenderer: (rendererContext) {
        return PlutoAggregateColumnFooter(
          rendererContext: rendererContext,
          formatAsCurrency: true,
          type: PlutoAggregateColumnType.sum,
          format: '#,###',
          alignment: Alignment.center,
          titleSpanBuilder: (text) {
            return [
              const TextSpan(
                text: 'Sum',
                style: TextStyle(color: Colors.red),
              ),
              const TextSpan(text: ' : '),
              TextSpan(text: text),
            ];
          },
        );
      },
    ),
  ];

  final List<PlutoRow> rows = [
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user1'),
        'name': PlutoCell(value: 'Mike'),
        'age': PlutoCell(value: 20),
        'role': PlutoCell(value: 'Programmer'),
        'joined': PlutoCell(value: '2021-01-01'),
        'working_time': PlutoCell(value: '09:00'),
        'salary': PlutoCell(value: 300),
      },
    ),
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user2'),
        'name': PlutoCell(value: 'Jack'),
        'age': PlutoCell(value: 25),
        'role': PlutoCell(value: 'Designer'),
        'joined': PlutoCell(value: '2021-02-01'),
        'working_time': PlutoCell(value: '10:00'),
        'salary': PlutoCell(value: 400),
      },
    ),
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user3'),
        'name': PlutoCell(value: 'Suzi'),
        'age': PlutoCell(value: 40),
        'role': PlutoCell(value: 'Owner'),
        'joined': PlutoCell(value: '2021-03-01'),
        'working_time': PlutoCell(value: '11:00'),
        'salary': PlutoCell(value: 700),
      },
    ),
  ];

  /// [PlutoGridStateManager] has many methods and properties to dynamically manipulate the grid.
  /// You can manipulate the grid dynamically at runtime by passing this through the [onLoaded] callback.
  PlutoGridStateManager? stateManager;

  void autoFitAllColumnsToContents(BuildContext context, PlutoGridStateManager stateManager) {
    for (var column in stateManager.columns) {
      stateManager.autoFitColumn(context, column);
    }
  }

  void _addRoundColumn() {
    if (stateManager == null) return;

    // Find the highest numbered "Round" column
    final roundColumns = stateManager!.columns
        .where((column) => column.title.startsWith('Round '))
        .toList();

    int maxRound = 0;
    for (var col in roundColumns) {
      final match = RegExp(r'Round (\d+)').firstMatch(col.title);
      if (match != null) {
        int num = int.parse(match.group(1)!);
        if (num > maxRound) maxRound = num;
      }
    }

    int nextRound = maxRound + 1;
    String newTitle = 'Round $nextRound';
    String newField = 'round_$nextRound';

    stateManager!.insertColumns(
      stateManager!.columns.length,
      [
        PlutoColumn(
          title: newTitle,
          field: newField,
          type: PlutoColumnType.number(),
        ),
      ],
    );

    // Add cells for the new column to all existing rows
    for (var row in stateManager!.rows) {
      row.cells[newField] = PlutoCell(value: null);
    }

    autoFitAllColumnsToContents(context, stateManager!);

    stateManager!.notifyListeners();
  }

  void _removeHighestRoundColumn() {
    if (stateManager == null) return;

    final roundColumns = stateManager!.columns
        .where((column) => column.title.startsWith('Round '))
        .toList();

    if (roundColumns.isEmpty) return;

    // Find the column with the highest "Round" number
    PlutoColumn? highestRoundColumn;
    int maxRound = -1;

    for (var col in roundColumns) {
      final match = RegExp(r'Round (\d+)').firstMatch(col.title);
      if (match != null) {
        int num = int.parse(match.group(1)!);
        if (num > maxRound) {
          maxRound = num;
          highestRoundColumn = col;
        }
      }
    }

    if (highestRoundColumn != null) {
      stateManager!.removeColumns([highestRoundColumn]);

      // Optional: Clean up cells in rows
      for (var row in stateManager!.rows) {
        row.cells.remove(highestRoundColumn.field);
      }

      stateManager!.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addRoundColumn,
                icon: const Icon(Icons.add),
                label: const Text('Add Column'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _removeHighestRoundColumn,
                icon: const Icon(Icons.remove),
                label: const Text('Remove Column'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                stateManager!.setShowColumnFilter(true);

                autoFitAllColumnsToContents(context, stateManager!);
              },
              onChanged: (PlutoGridOnChangedEvent event) {
                print(event);
              },
              configuration: const PlutoGridConfiguration(),
            ),
          ),
        ],
      ),
    );
  }
}
