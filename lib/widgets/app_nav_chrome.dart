// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../model/project_store.dart';
import '../navigation/app_routes.dart';
import 'app_back_button.dart';

/// Shared app-bar navigation controls used across project routes.
abstract final class AppNavChrome {
  /// Leading back control when the navigator can pop; otherwise `null`.
  static Widget? backLeading(BuildContext context) {
    if (!Navigator.canPop(context)) return null;
    return AppBackButton(onPressed: () => Navigator.of(context).pop());
  }

  /// Home action that persists the selection and clears the stack to Projects.
  static Widget homeAction({
    required BuildContext context,
    required ProjectStore store,
  }) {
    return IconButton(
      tooltip: 'Projects',
      icon: const Icon(Icons.home_outlined),
      onPressed: () => _goHome(context, store),
    );
  }

  /// Opens the scaffold drawer (must be built under a [Scaffold]).
  static Widget drawerAction() {
    return Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  static Future<void> _goHome(
    BuildContext context,
    ProjectStore store,
  ) async {
    final navigator = Navigator.of(context);
    await store.persistSelectedProject();
    if (!context.mounted) return;
    await AppRoutes.goToProjects(navigator);
  }
}
