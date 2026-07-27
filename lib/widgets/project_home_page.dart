// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/project_configuration.dart';
import '../help/help_instructions.dart';
import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../model/theme_controller.dart';
import '../navigation/app_routes.dart';
import '../styles/app_design.dart';
import '../styles/layout/app_layout.dart';
import '../styles/tokens/app_headings.dart';
import '../styles/tokens/app_radius.dart';
import '../styles/tokens/app_spacing.dart';
import '../util/format_timestamp.dart';
import 'app_bar_actions.dart';
import 'app_brand_bar.dart';
import 'app_copyright_footer.dart';
import 'confirm_delete_project_dialog.dart';

/// Home route listing saved projects and the create-project action.
class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({super.key});

  /// Mobile portrait: Instructions moves to a bottom-right FAB so the banner
  /// keeps more room for the logo and tagline.
  static bool _useInstructionsFab(
    BuildContext context,
    AppLayoutMetrics layout,
  ) {
    return layout.isMobile &&
        MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return AppLayoutBuilder(
      builder: (context, layout) {
        final instructionsAsFab = _useInstructionsFab(context, layout);
        final metrics = ProjectsBannerMetrics.of(
          context,
          includeHelpAction: !instructionsAsFab,
        );
        final appBarActions = <AppBarActionItem>[
          if (ProjectConfiguration.current.featureFlags.isEnabled(
            FeatureFlag.themeModeToggle,
          ))
            _themeModeAction(context),
          if (!instructionsAsFab) AppBarActionBar.instructions(context),
        ];

        // Atmosphere is painted app-wide in [MaterialApp.builder]; this scaffold
        // stays transparent so it shows through the banner as well.
        return Scaffold(
          appBar: ProjectsBannerAppBar(
            metrics: metrics,
            actions: AppBarActionBar.build(
              context,
              layout: layout,
              items: appBarActions,
            ),
          ),
          body: AppResponsiveBody(
            maxWidth: (layout) => layout.homeMaxWidth,
            builder: (context, layout) => !store.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(
                    context,
                    store,
                    layout,
                    clearFloatingAction: instructionsAsFab,
                  ),
          ),
          floatingActionButton: instructionsAsFab
              ? const _InstructionsFab()
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const AppCopyrightFooter(),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProjectStore store,
    AppLayoutMetrics _, {
    bool clearFloatingAction = false,
  }) {
    final projects = store.projects;
    final bottomClearance = clearFloatingAction
        ? AppDesign.homeInstructionsFabClearance
        : AppSpacing.xl;

    if (projects.isEmpty) {
      // Center the empty state when there is room, but allow it to scroll so
      // it never clips under heavy browser zoom or large text-scale settings.
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < AppDesign.emptyStateCompactHeight;
          final blockGap = compact ? AppSpacing.lg : AppSpacing.xxl;
          final scheme = Theme.of(context).colorScheme;

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : 0,
              ),
              child: Align(
                alignment: compact ? Alignment.topCenter : Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDesign.emptyStateMaxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: AppRadius.xlRadius,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          size: compact
                              ? AppDesign.emptyStateCompactIconSize
                              : AppDesign.emptyStateIconSize,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(height: blockGap),
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
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: blockGap),
                      FilledButton.icon(
                        onPressed: () => _createProject(context, store),
                        icon: const Icon(Icons.add),
                        label: Text(
                          ProjectConfiguration
                              .current
                              .uiCopy
                              .createProjectLabel,
                        ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomClearance),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => _createProject(context, store),
                  icon: const Icon(Icons.add),
                  label: Text(
                    ProjectConfiguration.current.uiCopy.createProjectLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Projects', style: AppHeadings.h3(context)),
                const SizedBox(height: AppSpacing.md),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _ProjectListTile(project: projects[index]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createProject(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    await store.createProject();
    if (!context.mounted) return;
    await navigator.pushNamed(AppRoutes.projectForm);
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
    if (!context.mounted) return;
    await navigator.pushNamed(AppRoutes.destinationForProject(project));
  }

  Future<void> _deleteProject(BuildContext context) async {
    final store = context.read<ProjectStore>();
    final confirmed = await confirmDeleteProject(context, project);

    if (!confirmed || !context.mounted) return;

    await store.deleteProject(project.id);
  }
}

AppBarActionItem _themeModeAction(BuildContext context) {
  final controller = context.watch<ThemeController>();
  final isDark = controller.isDarkActive(context);

  return AppBarActionItem(
    label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
    tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    onPressed: () => controller.setDarkMode(enabled: !isDark),
  );
}

/// Compact primary FAB used for Instructions on mobile portrait Projects.
class _InstructionsFab extends StatelessWidget {
  const _InstructionsFab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      tooltip: 'Instructions',
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: AppDesign.elevationFloating,
      onPressed: () => showHelpInstructionsSheet(context),
      child: const Icon(Icons.menu_book_outlined),
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
      child: Icon(
        icon,
        color: foreground,
        size: AppDesign.leadingIconGlyphSize,
      ),
    );
  }
}
