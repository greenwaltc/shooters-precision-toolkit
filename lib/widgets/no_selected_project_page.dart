// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../styles/layout/app_layout.dart';
import 'app_bar_actions.dart';
import 'app_brand_bar.dart';
import 'app_copyright_footer.dart';
import 'app_nav_chrome.dart';

class NoSelectedProjectPage extends StatelessWidget {
  const NoSelectedProjectPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppLayoutBuilder(
      builder: (context, layout) {
        final hasLeading = AppNavChrome.canPop(context);
        final actionItems = [AppBarActionBar.instructions(context)];
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
              onPressed: () =>
                  AppRoutes.goToProjects(Navigator.of(context)),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Projects'),
            ),
          ),
          bottomNavigationBar: const AppCopyrightFooter(),
        );
      },
    );
  }
}
