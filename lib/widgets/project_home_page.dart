import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../help/help_instructions.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../navigation/app_routes.dart';
import '../util/format_timestamp.dart';
import 'confirm_delete_project_dialog.dart';

class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return Scaffold(
      appBar: AppBar(title: const Text("Shooter's Precision Toolkit")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: !store.isLoaded
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, store),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHelp(context),
        child: const Icon(Icons.question_mark_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
    );
  }

  Widget _buildBody(BuildContext context, ProjectStore store) {
    if (store.projects.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 56.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No projects yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16.0),
              FilledButton.icon(
                onPressed: () => _createProject(context, store),
                icon: const Icon(Icons.add),
                label: const Text('Create a New Project'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _createProject(context, store),
          icon: const Icon(Icons.add),
          label: const Text('Create a New Project'),
        ),
        const SizedBox(height: 16.0),
        Text('Projects', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8.0),
        Expanded(
          child: ListView.separated(
            itemCount: store.projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8.0),
            itemBuilder: (context, index) {
              return _ProjectListTile(project: store.projects[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createProject(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    await store.createProject();
    navigator.pushNamed(AppRoutes.projectForm);
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          width: MediaQuery.of(context).size.width,
          child: const HelpInstructions(),
        );
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      isScrollControlled: true,
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.project});

  final SavedProject project;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: const Icon(Icons.analytics_outlined),
        title: Text(project.displayName),
        subtitle: Text(
          'Created ${formatProjectTimestamp(project.createdAt)}\n'
          'Modified ${formatProjectTimestamp(project.updatedAt)}',
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 96.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Delete project',
                onPressed: () => _deleteProject(context),
                icon: const Icon(Icons.delete_outline),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        onTap: () => _openProject(context),
      ),
    );
  }

  Future<void> _openProject(BuildContext context) async {
    final store = context.read<ProjectStore>();
    final navigator = Navigator.of(context);

    await store.persistSelectedProject();
    await store.selectProject(project.id);
    navigator.pushNamed(AppRoutes.anomrMatrix);
  }

  Future<void> _deleteProject(BuildContext context) async {
    final store = context.read<ProjectStore>();
    final confirmed = await confirmDeleteProject(context, project);

    if (!confirmed || !context.mounted) return;

    await store.deleteProject(project.id);
  }
}
