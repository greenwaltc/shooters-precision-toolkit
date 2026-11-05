import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/foundation/behavior_policy.dart';
import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/app_bar_actions.dart';
import '../../../../shared/ui/app_brand_bar.dart';
import '../../../../shared/ui/format_timestamp.dart';
import '../../../../shared/ui/navigation/app_routes.dart';
import '../../../../shared/ui/product_configuration.dart';
import '../../../../shared/ui/theme/app_design.dart';
import '../../../../shared/ui/theme/layout/app_layout.dart';
import '../../../../shared/ui/theme/theme_controller.dart';
import '../../../../shared/ui/theme/tokens/app_headings.dart';
import '../../../../shared/ui/theme/tokens/app_radius.dart';
import '../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../../domain/project_file_codec.dart';
import '../project_file_transfer.dart';
import '../project_store.dart';
import '../saved_project.dart';
import '../widgets/confirm_delete_project_dialog.dart';
import '../widgets/workspace_footer.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Home route listing saved projects and the create-project action.
class ProjectHomePage extends StatefulWidget {
  /// Opens the project list and creation actions for the current workspace.
  const ProjectHomePage({super.key});

  @override
  State<ProjectHomePage> createState() => _ProjectHomePageState();
}

class _ProjectHomePageState extends State<ProjectHomePage> {
  final _cloningProjects = <String>{};
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return AppLayoutBuilder(
      builder: (context, layout) {
        final appBarActions = <AppBarActionItem>[
          if (ProjectConfigurationScope.of(
            context,
          ).featureFlags.isEnabled(FeatureFlag.themeModeToggle))
            _themeModeAction(context),
          AppBarActionBar.instructions(context),
          AppBarActionBar.contact(context),
          AppBarActionBar.donations(context),
          ...AppBarActionBar.signOutActions(context),
        ];

        final actionsMetrics = AppBarActionsMetrics.of(
          context,
          layout: layout,
          items: appBarActions,
        );
        final metrics = ProjectsBannerMetrics.of(
          context,
          actionsWidth: actionsMetrics.actionsWidth,
        );

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
            builder: (context, layout) =>
                store.loadState == WorkspaceLoadState.loading ||
                    store.loadState == WorkspaceLoadState.error
                ? Center(
                    child: store.loadError == null
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.l10n.unableToLoadYourProjects),
                              TextButton(
                                onPressed: store.load,
                                child: Text(context.l10n.retry),
                              ),
                            ],
                          ),
                  )
                : _buildBody(
                    context,
                    store,
                    layout,
                    clearFloatingAction: false,
                  ),
          ),
          bottomNavigationBar: const WorkspaceFooter(showSaveStatus: false),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProjectStore store,
    AppLayoutMetrics layout, {
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
                        context.l10n.noProjectsYet,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.createYourFirstProjectToStartMeasuringHow,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: blockGap),
                      _projectActions(context, store, layout),
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
                if (layout.isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.projects,
                          style: AppHeadings.h3(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Flexible(
                        flex: 3,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _projectActions(context, store, layout),
                        ),
                      ),
                    ],
                  ),
                if (!layout.isDesktop) _projectActions(context, store, layout),
                SizedBox(
                  height: layout.isMobile ? AppSpacing.md : AppSpacing.xl,
                ),
                if (!layout.isDesktop)
                  Text(context.l10n.projects, style: AppHeadings.h3(context)),
                const SizedBox(height: AppSpacing.md),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _ProjectListTile(
                      key: ValueKey(project.id),
                      project: project,
                      cloning: _cloningProjects.contains(project.id),
                      onClone: () => _cloneProject(store, project),
                    );
                  },
                ),
                if (store.olderProjectsError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(context.l10n.unableToLoadOlderProjectsPleaseTryAgain),
                ],
                if (store.hasMoreProjects || store.isLoadingOlder) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: store.isLoadingOlder
                        ? null
                        : store.loadOlderProjects,
                    child: Text(
                      store.isLoadingOlder
                          ? context.l10n.loadingOlderProjects
                          : store.olderProjectsError != null
                          ? context.l10n.retryLoadingOlderProjects
                          : context.l10n.loadOlderProjects,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _projectActions(
    BuildContext context,
    ProjectStore store,
    AppLayoutMetrics layout,
  ) {
    Widget action(String label, IconData icon, VoidCallback? onPressed) {
      if (layout.isMobile) {
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
          ),
          child: Text(label, textAlign: TextAlign.center),
        );
      }
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: action(
            _importing
                ? context.l10n.importingProject
                : context.l10n.importProjectAction,
            Icons.file_open_outlined,
            _importing ? null : () => _importProject(store),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          flex: 2,
          child: action(
            ProjectConfigurationScope.of(context).uiCopy.createProjectLabel,
            Icons.add,
            () => _createProject(context, store),
          ),
        ),
      ],
    );
  }

  Future<void> _importProject(ProjectStore store) async {
    if (_importing) return;
    final transfer = context.read<ProjectFileTransfer>();
    final l10n = context.l10n;
    var readComplete = false;
    setState(() => _importing = true);
    void showMessage(String message) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    try {
      final snapshot = await transfer.pickProject(l10n.importProjectTitle);
      if (snapshot == null || !mounted) return;
      readComplete = true;
      await store.importProject(snapshot);
      showMessage(l10n.projectImportSuccess);
    } on UnsupportedProjectFileVersion catch (error) {
      showMessage(
        l10n.projectFileVersionMismatch(
          error.version,
          ProjectFileCodec.supportedVersion,
        ),
      );
    } on FormatException {
      showMessage(
        l10n.projectFileInvalid(BehaviorPolicy.maxProjectFileBytes ~/ 1024),
      );
    } catch (_) {
      showMessage(
        readComplete ? l10n.projectImportFailure : l10n.projectFileReadFailure,
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Clones this row's project without changing the current route or selection.
  Future<void> _cloneProject(ProjectStore store, SavedProject project) async {
    if (_cloningProjects.contains(project.id)) return;
    final title = context.l10n.cloneOfProject(project.displayName);
    setState(() => _cloningProjects.add(project.id));
    try {
      await store.cloneProject(project.id, title: title);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.unableToCloneProject)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cloningProjects.remove(project.id));
      }
    }
  }

  Future<void> _createProject(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    await store.createProject();
    if (!context.mounted) {
      return;
    }
    await navigator.pushNamed(AppRoutes.projectForm);
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({
    super.key,
    required this.project,
    required this.cloning,
    required this.onClone,
  });

  final SavedProject project;
  final bool cloning;
  final VoidCallback onClone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: AppRadius.lgRadius,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: MediaQuery.sizeOf(context).width >= 1024
              ? 4
              : AppSpacing.sm,
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
          MediaQuery.sizeOf(context).width >= 1024
              ? context.l10n.createdModified(
                  formatProjectTimestamp(
                    project.createdAt,
                    locale: Localizations.localeOf(context).toLanguageTag(),
                  ),
                  formatProjectTimestamp(
                    project.updatedAt,
                    locale: Localizations.localeOf(context).toLanguageTag(),
                  ),
                )
              : context.l10n.createdModifiedLines(
                  formatProjectTimestamp(
                    project.createdAt,
                    locale: Localizations.localeOf(context).toLanguageTag(),
                  ),
                  formatProjectTimestamp(
                    project.updatedAt,
                    locale: Localizations.localeOf(context).toLanguageTag(),
                  ),
                ),
        ),
        isThreeLine: MediaQuery.sizeOf(context).width < 1024,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.deleteProjectAction,
              onPressed: () => _deleteProject(context),
              icon: const Icon(Icons.delete_outline),
            ),
            IconButton(
              tooltip: context.l10n.cloneProjectAction,
              onPressed: cloning ? null : onClone,
              icon: cloning
                  ? const SizedBox.square(
                      dimension: AppDesign.space20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.content_copy_outlined),
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
    if (!context.mounted) {
      return;
    }
    await navigator.pushNamed(
      AppRoutes.destinationForProject(setupComplete: project.setupComplete),
    );
  }

  Future<void> _deleteProject(BuildContext context) async {
    final store = context.read<ProjectStore>();
    final confirmed = await confirmDeleteProject(context, project);

    if (!confirmed || !context.mounted) {
      return;
    }

    await store.deleteProject(project.id);
  }
}

AppBarActionItem _themeModeAction(BuildContext context) {
  final controller = context.watch<ThemeController>();
  final isDark = controller.isDarkActive(context);

  return AppBarActionItem(
    label: isDark
        ? context.l10n.switchToLightMode
        : context.l10n.switchToDarkMode,
    icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
    tooltip: isDark
        ? context.l10n.switchToLightMode
        : context.l10n.switchToDarkMode,
    onPressed: () => controller.setDarkMode(enabled: !isDark),
  );
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
