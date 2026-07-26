// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/widgets.dart';

import '../model/saved_project.dart';

/// Named routes and route-selection helpers used by `MaterialApp`.
class AppRoutes {
  static const projects = '/';
  static const projectForm = '/project-form';
  static const anomrMatrix = '/anomr-matrix';
  static const anomrResults = '/anomr-results';

  /// [RouteSettings.arguments] value used when Project Setup is opened from
  /// the Data Matrix "tune" control. Submit then pops back to the matrix
  /// instead of pushing a second matrix route onto the stack.
  static const String projectFormOpenedFromMatrix = 'projectFormOpenedFromMatrix';

  /// Returns the route the user should land on for [project].
  static String destinationForProject(SavedProject project) {
    return project.setupComplete ? anomrMatrix : projectForm;
  }

  /// Whether the current route is Project Setup opened from the Data Matrix.
  static bool isProjectFormOpenedFromMatrix(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments ==
        projectFormOpenedFromMatrix;
  }

  /// Clears the navigation stack down to the Projects page.
  static Future<void> goToProjects(NavigatorState navigator) {
    return navigator.pushNamedAndRemoveUntil(projects, (_) => false);
  }

  /// Opens Project Setup on top of the Data Matrix so Back returns to it.
  static Future<Object?> openProjectFormFromMatrix(NavigatorState navigator) {
    return navigator.pushNamed(
      projectForm,
      arguments: projectFormOpenedFromMatrix,
    );
  }
}
