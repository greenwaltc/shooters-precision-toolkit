// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_gate.dart';
import 'auth/auth_page.dart';
import 'auth/auth_service.dart';
import 'auth/workspace_sign_out.dart';
import 'config/project_configuration.dart';
import 'contact/contact_page.dart';
import 'firebase/firebase_bootstrap.dart';
import 'firebase/firebase_startup.dart';
import 'model/project_store.dart';
import 'model/theme_controller.dart';
import 'navigation/app_page_transitions.dart';
import 'navigation/app_routes.dart';
import 'storage/firestore_project_repository.dart';
import 'storage/project_draft_storage.dart';
import 'styles/app_theme.dart';
import 'widgets/anomr_matrix.dart';
import 'widgets/anomr_results_page.dart';
import 'widgets/app_background.dart';
import 'widgets/project_form_page.dart';
import 'widgets/project_home_page.dart';
import 'widgets/project_save_status.dart';

/// Boots Flutter and mounts the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FirebaseStartup(
      initialize: bootstrapFirebase,
      applicationBuilder: (services) => FirebaseApplication(services: services),
    ),
  );
}

/// Firebase services and one repository per signed-in account.
class FirebaseApplication extends StatelessWidget {
  const FirebaseApplication({
    super.key,
    required this.services,
    this.repositoryForUser,
  });

  final FirebaseServices services;
  final ProjectRepository Function(String uid)? repositoryForUser;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<FirebaseServices>.value(value: services),
      Provider<AuthService>(create: (_) => AuthService(services.auth)),
    ],
    child: AuthGate(
      auth: services.auth,
      signedOutBuilder: (_) => const AuthPage(key: ValueKey('signed-out')),
      verifyEmailBuilder: (_) => AuthPage(
        key: ValueKey('verify/${services.auth.currentUser?.uid}'),
        verification: true,
      ),
      signedInBuilder: (_, user) => MyApp(
        key: ValueKey('${services.app.options.projectId}/${user.uid}'),
        projectRepository:
            repositoryForUser?.call(user.uid) ??
            FirestoreProjectRepository(db: services.db, uid: user.uid),
        // Cloud-only scope: edits exist only for this account session until saved.
        projectDraftStorage: InMemoryProjectDraftStorage(),
      ),
    ),
  );
}

final Map<String, WidgetBuilder> _appRoutes = {
  AppRoutes.contact: (_) => const ContactPage(),
  AppRoutes.projects: (_) => const ProjectHomePage(),
  AppRoutes.projectForm: (_) => const ProjectFormPage(),
  AppRoutes.anomrMatrix: (_) => const AnomrMatrix(),
  AppRoutes.anomrResults: (_) => const AnomrResultsPage(),
};

/// Root widget that owns the project store and theme controller unless they
/// are injected (e.g. for tests).
class MyApp extends StatefulWidget {
  MyApp({
    super.key,
    this.projectStore,
    this.themeController,
    this.projectRepository,
    this.projectDraftStorage,
  }) {
    if (projectStore == null && projectRepository == null) {
      throw ArgumentError('Provide a project store or repository.');
    }
  }

  final ProjectStore? projectStore;
  final ThemeController? themeController;
  final ProjectRepository? projectRepository;
  final ProjectDraftStorage? projectDraftStorage;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
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
        ProjectStore(
          repository: widget.projectRepository!,
          draftStorage: widget.projectDraftStorage,
        );
    // The store exposes startup failures through loadState while this State
    // owns disposal. Injected stores remain owned by their caller.
    unawaited(_projectStore.load());

    _ownsThemeController = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeController();
    // Preference I/O failures retain the default; unexpected errors are reported
    // at the Flutter boundary. ThemeController ignores late loads after dispose.
    unawaited(
      _themeController.load().onError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'application startup',
            context: ErrorDescription('while loading the theme preference'),
          ),
        );
      }),
    );
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
    final auth = context.read<AuthService?>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectStore>.value(value: _projectStore),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
        if (auth != null)
          Provider<WorkspaceSignOut>(
            create: (_) => WorkspaceSignOut(
              flush: _projectStore.flush,
              signOut: auth.signOut,
            ),
          ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: ProjectConfiguration.current.brand.appTitle,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _resolveThemeMode(themeController),
            initialRoute: AppRoutes.projects,
            builder: (context, child) =>
                AppBackground(child: child ?? const SizedBox.shrink()),
            onGenerateRoute: (settings) {
              final builder = _appRoutes[settings.name];
              if (builder == null) {
                return null;
              }
              return AppPageRoute<void>(
                settings: settings,
                builder: (context) {
                  final page = builder(context);
                  // Editors show status in their banners; Results needs no
                  // floating footer status.
                  if (settings.name == AppRoutes.projectForm ||
                      settings.name == AppRoutes.anomrMatrix ||
                      settings.name == AppRoutes.anomrResults) {
                    return page;
                  }
                  return ProjectWorkspaceFrame(
                    navigatorKey: _navigatorKey,
                    child: page,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
