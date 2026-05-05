import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../help/help_instructions.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../navigation/app_routes.dart';
import '../styles/tokens/app_radius.dart';
import '../styles/tokens/app_spacing.dart';
import '../util/format_timestamp.dart';
import 'confirm_delete_project_dialog.dart';

class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({super.key});

  /// Maximum width of the empty-state column on wide viewports.
  static const double _emptyStateMaxWidth = 420;

  /// Size of the leading hero icon on the empty state.
  static const double _emptyStateIconSize = 56;

  /// Help bottom sheet height as a fraction of the screen.
  static const double _helpSheetHeightFactor = 0.75;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return Scaffold(
      appBar: AppBar(title: const Text("Shooter's Precision Toolkit")),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
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
          constraints: const BoxConstraints(maxWidth: _emptyStateMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: _emptyStateIconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'No projects yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
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
        const SizedBox(height: AppSpacing.xl),
        Text('Projects', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: store.projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
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
          height: MediaQuery.of(context).size.height * _helpSheetHeightFactor,
          width: MediaQuery.of(context).size.width,
          child: const HelpInstructions(),
        );
      },
      isScrollControlled: true,
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.project});

  final SavedProject project;

  /// Width reserved for the trailing actions column.
  static const double _trailingWidth = 96;

  @override
  Widget build(BuildContext context) {
    return Card(
      // Compact radius variant for list cards (cards default to AppRadius.sm
      // in AppTheme; setting it explicitly keeps the local style obvious).
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppRadius.smRadius,
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
          width: _trailingWidth,
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
