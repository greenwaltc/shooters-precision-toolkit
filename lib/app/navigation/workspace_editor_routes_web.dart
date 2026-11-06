import 'package:flutter/widgets.dart';

import '../../features/experiments/presentation/matrix/data_matrix_page.dart'
    deferred as matrix;
import '../../features/experiments/presentation/results/results_page.dart'
    deferred as results;
import '../../features/experiments/presentation/test_design/project_form_page.dart'
    deferred as design;
import '../../shared/ui/navigation/app_routes.dart';
import 'deferred_workspace_page.dart';

/// Downloads editor and results code on the first visit to each route.
final Map<String, WidgetBuilder> workspaceEditorRoutes = {
  AppRoutes.projectForm: (_) => DeferredWorkspacePage(
    load: () => design.loadLibrary(),
    builder: (_) => design.ProjectFormPage(),
  ),
  AppRoutes.anomrMatrix: (_) => DeferredWorkspacePage(
    load: () => matrix.loadLibrary(),
    builder: (_) => matrix.AnomrMatrix(),
  ),
  AppRoutes.anomrResults: (_) => DeferredWorkspacePage(
    load: () => results.loadLibrary(),
    builder: (_) => results.AnomrResultsPage(),
  ),
};
