import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../project_store.dart';
import '../test_design/project_form_model.dart';
import '../widgets/no_selected_project_page.dart';
import 'widgets/results_view.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Public entry point for the ANOMR results route.
///
/// Reads the [PlutoGridStateManager] passed as a route argument, scopes the
/// form model + state manager into the widget tree, and delegates rendering
/// to [ResultsView]. All real work lives under `lib/widgets/anomr_results/`.
class AnomrResultsPage extends StatelessWidget {
  /// Opens the results page for the selected project.
  const AnomrResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! PlutoGridStateManager) {
      return NoSelectedProjectPage(title: context.l10n.results);
    }
    final stateManager = arguments;

    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;

    if (project == null) {
      return NoSelectedProjectPage(title: context.l10n.results);
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
