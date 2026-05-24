// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';
import '../model/project_store.dart';
import 'anomr_results/widgets/results_view.dart';
import 'no_selected_project_page.dart';

/// Public entry point for the ANOMR results route.
///
/// Reads the [PlutoGridStateManager] passed as a route argument, scopes the
/// form model + state manager into the widget tree, and delegates rendering
/// to [ResultsView]. All real work lives under `lib/widgets/anomr_results/`.
class AnomrResultsPage extends StatelessWidget {
  const AnomrResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! PlutoGridStateManager) {
      return const NoSelectedProjectPage(title: 'Results');
    }
    final stateManager = arguments;

    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return const NoSelectedProjectPage(title: 'Results');
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectFormModel>.value(
          value: project.formModel,
        ),
        ChangeNotifierProvider<PlutoGridStateManager>.value(
          value: stateManager,
        ),
      ],
      child: const ResultsView(),
    );
  }
}
