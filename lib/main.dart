// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/project_configuration.dart';
import 'model/project_store.dart';
import 'model/theme_controller.dart';
import 'navigation/app_routes.dart';
import 'storage/project_storage.dart';
import 'styles/app_theme.dart';
import 'styles/layout/app_viewport.dart';
import 'widgets/anomr_matrix.dart';
import 'widgets/anomr_results_page.dart';
import 'widgets/project_form_page.dart';
import 'widgets/project_home_page.dart';

/// Boots Flutter and mounts the application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Root widget that owns the project store and theme controller unless they
/// are injected (e.g. for tests).
class MyApp extends StatefulWidget {
  const MyApp({super.key, this.projectStore, this.themeController});

  final ProjectStore? projectStore;
  final ThemeController? themeController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProjectStore _projectStore;
  late final ThemeController _themeController;
  late final bool _ownsProjectStore;
  late final bool _ownsThemeController;

  @override
  void initState() {
    super.initState();

    _ownsProjectStore = widget.projectStore == null;
    _projectStore =
        widget.projectStore ??
        ProjectStore(storage: SharedPreferencesProjectStorage());
    unawaited(_projectStore.load());

    _ownsThemeController = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeController();
    unawaited(_themeController.load());
  }

  @override
  void dispose() {
    if (_ownsProjectStore) {
      _projectStore.dispose();
    }
    if (_ownsThemeController) {
      _themeController.dispose();
    }
    super.dispose();
  }

  /// Honors the user's saved preference only while the theme toggle is
  /// enabled; the app is otherwise pinned to its light theme.
  ThemeMode _resolveThemeMode(ThemeController controller) {
    final canToggle = ProjectConfiguration.current.featureFlags.isEnabled(
      FeatureFlag.themeModeToggle,
    );
    return canToggle ? controller.themeMode : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectStore>.value(value: _projectStore),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: ProjectConfiguration.current.brand.appTitle,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _resolveThemeMode(themeController),
            initialRoute: AppRoutes.projects,
            builder: (context, child) {
              return MediaQuery(
                data: AppViewport.applyWebSafeArea(MediaQuery.of(context)),
                child: child ?? const SizedBox.shrink(),
              );
            },
            routes: {
              AppRoutes.projects: (_) => const ProjectHomePage(),
              AppRoutes.projectForm: (_) => const ProjectFormPage(),
              AppRoutes.anomrMatrix: (_) => const AnomrMatrix(),
              AppRoutes.anomrResults: (_) => const AnomrResultsPage(),
            },
          );
        },
      ),
    );
  }
}
