import 'package:flutter/material.dart';
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('ANOMR Matrix', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12.0),
            Text(
              formModel.projectTitle.trim().isEmpty
                  ? project.displayName
                  : formModel.projectTitle.trim(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(formModel.experimentStructure.label),
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
