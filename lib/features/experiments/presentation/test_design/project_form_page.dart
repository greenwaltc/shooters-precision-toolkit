import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/app_bar_actions.dart';
import '../../../../shared/ui/app_brand_bar.dart';
import '../../../../shared/ui/app_nav_chrome.dart';
import '../../../../shared/ui/navigation/app_routes.dart';
import '../../../../shared/ui/theme/layout/app_layout.dart';
import '../project_store.dart';
import '../widgets/no_selected_project_page.dart';
import '../widgets/project_save_status.dart';
import '../widgets/workspace_footer.dart';
import 'project_form.dart';
import 'project_form_model.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Route that hosts setup editing for the selected project.
class ProjectFormPage extends StatelessWidget {
  /// Opens the test design for the selected project.
  const ProjectFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return NoSelectedProjectPage(title: context.l10n.testDesign);
    }

    return ChangeNotifierProvider<ProjectFormModel>.value(
      value: project.formModel,
      child: Builder(
        builder: (context) {
          final formModel = context.watch<ProjectFormModel>();

          return AppLayoutBuilder(
            builder: (context, layout) {
              final hasLeading = AppNavChrome.canPop(context);
              final actionItems = [
                AppBarActionBar.instructions(context),
                AppBarActionBar.contact(context),
                AppBarActionBar.donations(context),
                AppNavChrome.homeActionItem(
                  context: context,
                  persistSelection: store.persistSelectedProject,
                ),
                ...AppBarActionBar.signOutActions(context),
              ];
              final actionsMetrics = AppBarActionsMetrics.of(
                context,
                layout: layout,
                items: actionItems,
                hasLeading: hasLeading,
              );
              final titleMetrics = AppBrandTitleMetrics.of(
                context,
                label: project.displayName,
                titleMaxWidth: actionsMetrics.titleMaxWidth,
              );

              return Scaffold(
                appBar: AppBar(
                  toolbarHeight: titleMetrics.toolbarHeight,
                  automaticallyImplyLeading: false,
                  leading: AppNavChrome.backLeading(context),
                  title: AppBrandTitle(
                    label: project.displayName,
                    metrics: titleMetrics,
                    trailing: ProjectSaveStatus(
                      inBanner: true,
                      compact: layout.isMobile,
                    ),
                  ),
                  actions: AppBarActionBar.build(
                    context,
                    layout: layout,
                    items: actionItems,
                    hasLeading: hasLeading,
                  ),
                ),
                body: AppResponsiveBody(
                  maxWidth: (layout) => layout.formMaxWidth,
                  builder: (context, _) => ProjectForm(
                    formModel: formModel,
                    onSubmit: () => _goToMatrix(context, store),
                  ),
                ),
                bottomNavigationBar: const WorkspaceFooter(
                  showSaveStatus: false,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _goToMatrix(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    final openedFromMatrix = AppRoutes.isProjectFormOpenedFromMatrix(context);

    if (!await store.completeProjectSetup()) {
      return;
    }
    await store.persistSelectedProject();
    if (!context.mounted) {
      return;
    }

    // Returning from the matrix "tune" path should pop back onto the existing
    // matrix page so the stack does not grow [matrix, form, matrix, ...].
    if (openedFromMatrix && navigator.canPop()) {
      navigator.pop();
      return;
    }

    await navigator.pushNamed(AppRoutes.anomrMatrix);
  }
}
