import 'package:flutter/material.dart';

import '../l10n/app_copy.dart';
import 'app_back_button.dart';
import 'app_bar_actions.dart';
import 'navigation/app_routes.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Shared app-bar navigation controls used across project routes.
abstract final class AppNavChrome {
  /// Leading back control when the navigator can pop; otherwise `null`.
  static Widget? backLeading(BuildContext context) {
    if (!Navigator.canPop(context)) {
      return null;
    }
    return AppBackButton(onPressed: () => Navigator.of(context).pop());
  }

  /// Whether the current route can show a back leading control.
  static bool canPop(BuildContext context) => Navigator.canPop(context);

  /// Home action that persists the selection and clears the stack to Projects.
  static AppBarActionItem homeActionItem({
    required BuildContext context,
    required Future<void> Function() persistSelection,
  }) {
    return AppBarActionItem(
      label: context.l10n.projects,
      icon: Icons.home_outlined,
      tooltip: context.l10n.projects,
      onPressed: () => goHome(context, persistSelection),
    );
  }

  /// Persists the selection and clears the stack to Projects.
  static Future<void> goHome(
    BuildContext context,
    Future<void> Function() persistSelection,
  ) async {
    final navigator = Navigator.of(context);
    await persistSelection();
    if (!context.mounted) {
      return;
    }
    await AppRoutes.goToProjects(navigator);
  }
}
