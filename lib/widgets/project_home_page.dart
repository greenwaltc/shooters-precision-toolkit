// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../help/help_access.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../model/theme_controller.dart';
import '../navigation/app_routes.dart';
import '../styles/app_design.dart';
import '../styles/layout/app_layout.dart';
import '../styles/tokens/app_radius.dart';
import '../styles/tokens/app_spacing.dart';
import '../util/format_timestamp.dart';
import 'app_copyright_footer.dart';
import 'confirm_delete_project_dialog.dart';

/// Home route listing saved projects and the create-project action.
class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({super.key});

  /// Maximum width of the empty-state column on wide viewports.
  static const double _emptyStateMaxWidth = 420;

  /// Size of the leading hero icon on the empty state.
  static const double _emptyStateIconSize = 56;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return AppLayoutBuilder(
      builder: (context, layout) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Bramwell's Precision Test Kit"),
            actions: [
              const _ThemeModeToggle(),
              ...helpAppBarActionsFor(layout),
            ],
          ),
          body: AppResponsiveBody(
            maxWidth: (layout) => layout.homeMaxWidth,
            builder: (context, layout) => !store.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, store, layout),
          ),
          floatingActionButton: helpFabFor(layout),
          floatingActionButtonLocation: helpFabLocation,
          bottomNavigationBar: const AppCopyrightFooter(),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProjectStore store,
    AppLayoutMetrics _,
  ) {
    final projects = store.projects;

    if (projects.isEmpty) {
      // Center the empty state when there is room, but allow it to scroll so
      // it never clips under heavy browser zoom or large text-scale settings.
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _emptyStateMaxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          borderRadius: AppRadius.xlRadius,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          size: _emptyStateIconSize,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'No projects yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Create your first project to start measuring how '
                        'your chosen factors influence precision.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FilledButton.icon(
                        onPressed: () => _createProject(context, store),
                        icon: const Icon(Icons.add),
                        label: const Text('Create a New Project'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _ProjectListTile(project: projects[index]);
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
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.project});

  final SavedProject project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: AppRadius.lgRadius,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        leading: _LeadingBadge(
          icon: Icons.analytics_outlined,
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
        title: Text(
          project.displayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Created ${formatProjectTimestamp(project.createdAt)}\n'
          'Modified ${formatProjectTimestamp(project.updatedAt)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Delete project',
              onPressed: () => _deleteProject(context),
              icon: const Icon(Icons.delete_outline),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
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
    navigator.pushNamed(AppRoutes.destinationForProject(project));
  }

  Future<void> _deleteProject(BuildContext context) async {
    final store = context.read<ProjectStore>();
    final confirmed = await confirmDeleteProject(context, project);

    if (!confirmed || !context.mounted) return;

    await store.deleteProject(project.id);
  }
}

/// App-bar control that flips the app between light and dark themes and
/// persists the choice via [ThemeController].
class _ThemeModeToggle extends StatelessWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.isDarkActive(context);

    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      onPressed: () => controller.setDarkMode(enabled: !isDark),
    );
  }
}

/// Tinted, rounded badge that frames a leading icon on list/hero surfaces.
class _LeadingBadge extends StatelessWidget {
  const _LeadingBadge({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDesign.leadingIconBadgeSize,
      height: AppDesign.leadingIconBadgeSize,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Icon(icon, color: foreground, size: 22),
    );
  }
}
