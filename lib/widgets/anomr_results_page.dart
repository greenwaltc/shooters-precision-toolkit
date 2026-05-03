import 'package:flutter/material.dart';
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
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const NoSelectedProjectPage(title: 'Results');
    }

    return ChangeNotifierProvider<ProjectFormModel>.value(
      value: project.formModel,
      child: Scaffold(
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
        body: const Center(
          child: Text('ANOMR Results Placeholder'),
        ),
      ),
    );
  }
}
