// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../help/help_access.dart';
import '../navigation/app_routes.dart';
import '../styles/layout/app_layout.dart';
import 'app_brand_bar.dart';
import 'app_copyright_footer.dart';

class NoSelectedProjectPage extends StatelessWidget {
  const NoSelectedProjectPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppLayoutBuilder(
      builder: (context, layout) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: AppBrandTitle.toolbarHeight,
            title: AppBrandTitle(label: title),
            actions: helpAppBarActionsFor(layout),
          ),
          body: Center(
            child: FilledButton.icon(
              onPressed: () =>
                  AppRoutes.goToProjects(Navigator.of(context)),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Projects'),
            ),
          ),
          floatingActionButton: helpFabFor(layout),
          floatingActionButtonLocation: helpFabLocation,
          bottomNavigationBar: const AppCopyrightFooter(),
        );
      },
    );
  }
}
