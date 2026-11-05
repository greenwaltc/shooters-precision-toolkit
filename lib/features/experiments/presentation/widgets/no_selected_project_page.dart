import 'package:flutter/material.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/app_bar_actions.dart';
import '../../../../shared/ui/app_brand_bar.dart';
import '../../../../shared/ui/app_nav_chrome.dart';
import '../../../../shared/ui/navigation/app_routes.dart';
import '../../../../shared/ui/theme/layout/app_layout.dart';
import 'workspace_footer.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// A workspace page shown when the requested action needs a selected project.
class NoSelectedProjectPage extends StatelessWidget {
  /// Creates the empty-selection page with the requested page [title].
  const NoSelectedProjectPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppLayoutBuilder(
      builder: (context, layout) {
        final hasLeading = AppNavChrome.canPop(context);
        final actionItems = [
          AppBarActionBar.instructions(context),
          AppBarActionBar.contact(context),
          AppBarActionBar.donations(context),
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
          label: title,
          titleMaxWidth: actionsMetrics.titleMaxWidth,
        );

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: titleMetrics.toolbarHeight,
            automaticallyImplyLeading: false,
            leading: AppNavChrome.backLeading(context),
            title: AppBrandTitle(label: title, metrics: titleMetrics),
            actions: AppBarActionBar.build(
              context,
              layout: layout,
              items: actionItems,
              hasLeading: hasLeading,
            ),
          ),
          body: Center(
            child: FilledButton.icon(
              onPressed: () => AppRoutes.goToProjects(Navigator.of(context)),
              icon: const Icon(Icons.home_outlined),
              label: Text(context.l10n.projects),
            ),
          ),
          bottomNavigationBar: const WorkspaceFooter(),
        );
      },
    );
  }
}
