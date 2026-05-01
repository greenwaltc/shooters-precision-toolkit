import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';
import '../model/project_store.dart';
import '../navigation/app_routes.dart';
import 'project_drawer.dart';
import 'project_form.dart';

class ProjectFormPage extends StatelessWidget {
  const ProjectFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const _NoSelectedProjectPage();
    }

    return ChangeNotifierProvider<ProjectFormModel>.value(
      value: project.formModel,
      child: Builder(
        builder: (context) {
          final formModel = context.watch<ProjectFormModel>();

          return Scaffold(
            drawer: const ProjectDrawer(),
            appBar: AppBar(
              title: Text(project.displayName),
              actions: [
                IconButton(
                  tooltip: 'Projects',
                  onPressed: () => _goHome(context, store),
                  icon: const Icon(Icons.home_outlined),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ProjectForm(
                  formModel: formModel,
                  onSubmit: () => _goToMatrix(context, store),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _goHome(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    await store.persistSelectedProject();
    navigator.pushNamedAndRemoveUntil(AppRoutes.projects, (_) => false);
  }

  Future<void> _goToMatrix(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    await store.persistSelectedProject();
    navigator.pushReplacementNamed(AppRoutes.anomrMatrix);
  }
}

class _NoSelectedProjectPage extends StatelessWidget {
  const _NoSelectedProjectPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Setup')),
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
