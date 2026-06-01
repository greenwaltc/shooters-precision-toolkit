// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import '../model/saved_project.dart';

/// Named routes and route-selection helpers used by `MaterialApp`.
class AppRoutes {
  static const projects = '/';
  static const projectForm = '/project-form';
  static const anomrMatrix = '/anomr-matrix';
  static const anomrResults = '/anomr-results';

  /// Returns the route the user should land on for [project].
  static String destinationForProject(SavedProject project) {
    return project.setupComplete ? anomrMatrix : projectForm;
  }
}
