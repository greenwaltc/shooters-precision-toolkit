import 'package:flutter/widgets.dart';

import '../../features/experiments/presentation/matrix/data_matrix_page.dart';
import '../../features/experiments/presentation/results/results_page.dart';
import '../../features/experiments/presentation/test_design/project_form_page.dart';
import '../../shared/ui/navigation/app_routes.dart';

/// Builds editor and results routes from the installed native app.
final Map<String, WidgetBuilder> workspaceEditorRoutes = {
  AppRoutes.projectForm: (_) => const ProjectFormPage(),
  AppRoutes.anomrMatrix: (_) => const AnomrMatrix(),
  AppRoutes.anomrResults: (_) => const AnomrResultsPage(),
};
