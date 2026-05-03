import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';
import '../model/project_store.dart';
import 'no_selected_project_page.dart';
import 'project_drawer.dart';
import 'package:fl_chart/fl_chart.dart';

class AnomrResultsPage extends StatelessWidget {
  const AnomrResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stateManager = ModalRoute.of(context)!.settings.arguments as PlutoGridStateManager;

    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const NoSelectedProjectPage(title: 'Results');
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectFormModel>.value(value: project.formModel),
        ChangeNotifierProvider<PlutoGridStateManager>.value(value: stateManager),
      ],
      child: const _ResultsView(),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView();

  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = context.watch<PlutoGridStateManager>();
    final project = context.read<ProjectStore>().selectedProject!;

    // Filter out null/invalid ranges to ensure accurate math
    final allRanges = stateManager.rows
        .map((row) => double.tryParse(row.cells['range']?.value?.toString() ?? ''))
        .whereType<double>() // Removes nulls
        .toList();

    final meanValue = _calculateMean(allRanges);

    return Scaffold(
      drawer: const ProjectDrawer(),
      appBar: AppBar(
        title: Text('${project.displayName} - Results'),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Analysis of Mean Ranges',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Grand Mean: ${meanValue.toStringAsFixed(4)}'),
            const SizedBox(height: 32),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: meanValue * 0.8, // Adjust scale for visibility
                  maxY: meanValue * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, meanValue), // Start point
                        FlSpot(10, meanValue), // End point (adjust X range as needed)
                      ],
                      isCurved: false,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 4,
                      // dotsConfig ensures markers only on the ends
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
