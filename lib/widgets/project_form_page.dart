// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../help/help_access.dart';
import '../model/project_form_model.dart';
import '../model/project_store.dart';
import '../navigation/app_routes.dart';
import '../styles/layout/app_layout.dart';
import 'app_brand_bar.dart';
import 'app_copyright_footer.dart';
import 'app_nav_chrome.dart';
import 'project_drawer.dart';
import 'project_form.dart';
import 'no_selected_project_page.dart';

/// Route that hosts setup editing for the selected project.
class ProjectFormPage extends StatelessWidget {
  const ProjectFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const NoSelectedProjectPage(title: 'Project Setup');
    }

    return ChangeNotifierProvider<ProjectFormModel>.value(
      value: project.formModel,
      child: Builder(
        builder: (context) {
          final formModel = context.watch<ProjectFormModel>();

          return AppLayoutBuilder(
            builder: (context, layout) {
              return Scaffold(
                drawer: const ProjectDrawer(),
                appBar: AppBar(
                  toolbarHeight: AppBrandTitle.toolbarHeight,
                  automaticallyImplyLeading: false,
                  leading: AppNavChrome.backLeading(context),
                  title: AppBrandTitle(label: project.displayName),
                  actions: [
                    ...helpAppBarActionsFor(layout),
                    AppNavChrome.homeAction(context: context, store: store),
                    AppNavChrome.drawerAction(),
                  ],
                ),
                body: AppResponsiveBody(
                  maxWidth: (layout) => layout.formMaxWidth,
                  builder: (context, _) => ProjectForm(
                    formModel: formModel,
                    onSubmit: () => _goToMatrix(context, store),
                  ),
                ),
                floatingActionButton: helpFabFor(layout),
                floatingActionButtonLocation: helpFabLocation,
                bottomNavigationBar: const AppCopyrightFooter(),
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

    if (!await store.completeProjectSetup()) return;
    await store.persistSelectedProject();
    if (!context.mounted) return;

    // Returning from the matrix "tune" path should pop back onto the existing
    // matrix page so the stack does not grow [matrix, form, matrix, ...].
    if (openedFromMatrix && navigator.canPop()) {
      navigator.pop();
      return;
    }

    await navigator.pushNamed(AppRoutes.anomrMatrix);
  }
}
