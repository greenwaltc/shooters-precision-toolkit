import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/api/auth_repository.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/workspace_sign_out.dart';
import '../features/contact/api/contact_sender.dart';
import '../features/contact/data/web3forms_contact_sender.dart';
import '../features/contact/presentation/contact_page.dart';
import '../features/experiments/data/firestore_project_repository.dart';
import '../features/experiments/data/project_draft_storage.dart';
import '../features/experiments/presentation/matrix/data_matrix_page.dart';
import '../features/experiments/presentation/project_file_transfer.dart';
import '../features/experiments/presentation/project_store.dart';
import '../features/experiments/presentation/projects/project_home_page.dart';
import '../features/experiments/presentation/results/results_page.dart';
import '../features/experiments/presentation/test_design/project_form_page.dart';
import '../features/experiments/presentation/widgets/project_save_status.dart';
import '../shared/foundation/behavior_policy.dart';
import '../shared/foundation/clipboard_events.dart';
import '../shared/foundation/diagnostics.dart';
import '../shared/foundation/external_links.dart';
import '../shared/foundation/file_loader.dart';
import '../shared/foundation/file_saver.dart';
import '../shared/l10n/app_copy.dart';
import '../shared/platform/clipboard_events_stub.dart'
    if (dart.library.js_interop) '../shared/platform/clipboard_events_web.dart';
import '../shared/platform/file_picker_loader.dart';
import '../shared/platform/file_picker_saver.dart';
import '../shared/platform/shared_preferences_theme_storage.dart';
import '../shared/platform/url_launcher_links.dart';
import '../shared/ui/app_background.dart';
import '../shared/ui/emulator_presentation.dart';
import '../shared/ui/navigation/app_page_transitions.dart';
import '../shared/ui/navigation/app_routes.dart';
import '../shared/ui/product_configuration.dart';
import '../shared/ui/theme/app_theme.dart';
import '../shared/ui/theme/theme_controller.dart';
import '../shared/ui/workspace_exit.dart';
import 'config/app_config.dart';
import 'firebase/firebase_bootstrap.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Firebase services and one repository per signed-in account.
class FirebaseApplication extends StatelessWidget {
  /// Creates the application around initialized Firebase [services].
  ///
  /// Supply [repositoryForUser] to select a different project repository for
  /// each signed-in account.
  const FirebaseApplication({
    super.key,
    required this.services,
    required this.clock,
    this.diagnostics = const NoopDiagnostics(),
    this.repositoryForUser,
  });

  final FirebaseServices services;
  final Clock clock;
  final Diagnostics diagnostics;
  final ProjectRepository Function(String uid)? repositoryForUser;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<FirebaseServices>.value(value: services),
      Provider<ExternalLinks>.value(
        value: UrlLauncherLinks(
          policy: ExternalLinkPolicy(
            allowedHosts: BehaviorPolicy.externalLinkHosts,
          ),
        ),
      ),
      Provider<AppConfig>.value(value: services.config),
      if (services.config.web3FormsAccessKey case final key?) ...[
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),
        Provider<ContactSender>(
          create: (context) => Web3FormsContactSender(
            client: context.read<http.Client>(),
            accessKey: key,
            diagnostics: diagnostics,
          ),
        ),
      ],
      Provider<EmulatorPresentation>.value(
        value: EmulatorPresentation(enabled: services.config.useEmulators),
      ),
      Provider<AuthRepository>(
        create: (_) => AuthService(
          services.auth,
          returnOrigin: services.config.publicOrigin,
          emailCooldown: services.config.emailCooldown,
          clock: clock,
          diagnostics: diagnostics,
        ),
      ),
    ],
    child: ProjectConfigurationScope(
      configuration: services.config.product,
      child: Consumer<AuthRepository>(
        builder: (context, auth, _) => AuthGate(
          auth: auth,
          signedOutBuilder: (_) => AuthPage(
            contactBuilder: _contactPage,
            key: ValueKey('signed-out'),
          ),
          verifyEmailBuilder: (_) => AuthPage(
            contactBuilder: _contactPage,
            key: ValueKey('verify/${services.auth.currentUser?.uid}'),
            verification: true,
          ),
          signedInBuilder: (_, user) => MyApp(
            key: ValueKey('${services.app.options.projectId}/${user.uid}'),
            config: services.config,
            random: Random(),
            clock: clock,
            diagnostics: diagnostics,
            themeController: null,
            projectRepository:
                repositoryForUser?.call(user.uid) ??
                FirestoreProjectRepository(db: services.db, uid: user.uid),
            // Cloud-only scope: edits exist only for this account session until saved.
            projectDraftStorage: InMemoryProjectDraftStorage(),
          ),
        ),
      ),
    ),
  );
}

Widget _contactPage(BuildContext context) =>
    ContactPage(sender: context.read<ContactSender?>());

final Map<String, WidgetBuilder> _appRoutes = {
  AppRoutes.contact: _contactPage,
  AppRoutes.projects: (_) => const ProjectHomePage(),
  AppRoutes.projectForm: (_) => const ProjectFormPage(),
  AppRoutes.anomrMatrix: (_) => const AnomrMatrix(),
  AppRoutes.anomrResults: (_) => const AnomrResultsPage(),
};

/// Root widget that owns the project store and theme controller unless they
/// are injected (e.g. for tests).
class MyApp extends StatefulWidget {
  /// Creates a workspace for one account.
  ///
  /// Supply [projectStore] or [projectRepository]. An injected store or theme
  /// controller stays owned by its caller. The workspace disposes instances it
  /// creates. [fileLoader] and [fileSaver] default to platform file dialogs.
  MyApp({
    super.key,
    required this.config,
    required this.random,
    required this.clock,
    this.diagnostics = const NoopDiagnostics(),
    this.projectStore,
    this.themeController,
    this.projectRepository,
    this.projectDraftStorage,
    this.fileLoader = const FilePickerLoader(),
    this.fileSaver = const FilePickerSaver(),
  }) {
    if (projectStore == null && projectRepository == null) {
      throw ArgumentError('Provide a project store or repository.');
    }
  }

  final AppConfig config;
  final Random random;
  final Clock clock;
  final Diagnostics diagnostics;
  final ProjectStore? projectStore;
  final ThemeController? themeController;
  final ProjectRepository? projectRepository;
  final ProjectDraftStorage? projectDraftStorage;
  final FileLoader fileLoader;
  final FileSaver fileSaver;

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
          clock: widget.clock,
          diagnostics: widget.diagnostics,
          draftStorage:
              widget.projectDraftStorage ?? InMemoryProjectDraftStorage(),
          saveDebounce: widget.config.saveDebounce,
          featureFlags: widget.config.product.featureFlags,
        );
    // The store exposes startup failures through loadState while this State
    // owns disposal. Injected stores remain owned by their caller.
    unawaited(_projectStore.load());

    _ownsThemeController = widget.themeController == null;
    _themeController =
        widget.themeController ??
        ThemeController(
          storage: SharedPreferencesThemeStorage(
            preferencesLoader: SharedPreferences.getInstance,
          ),
        );
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
    final canToggle = widget.config.product.featureFlags.isEnabled(
      FeatureFlag.themeModeToggle,
    );
    return canToggle ? controller.themeMode : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository?>();
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: widget.config),
        Provider<EmulatorPresentation>.value(
          value: EmulatorPresentation(enabled: widget.config.useEmulators),
        ),
        Provider<Random>.value(value: widget.random),
        Provider<Diagnostics>.value(value: widget.diagnostics),
        Provider<ClipboardEvents>.value(value: const BrowserClipboardEvents()),
        Provider<ExternalLinks>.value(
          value: UrlLauncherLinks(
            policy: ExternalLinkPolicy(
              allowedHosts: BehaviorPolicy.externalLinkHosts,
            ),
          ),
        ),
        Provider<FileSaver>.value(value: widget.fileSaver),
        Provider<ProjectFileTransfer>.value(
          value: ProjectFileTransfer(
            loader: widget.fileLoader,
            saver: widget.fileSaver,
          ),
        ),
        ChangeNotifierProvider<ProjectStore>.value(value: _projectStore),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
        if (auth != null)
          Provider<WorkspaceExit>(
            create: (_) => WorkspaceSignOut(
              flush: _projectStore.flush,
              signOut: auth.signOut,
            ),
          ),
      ],
      child: ProjectConfigurationScope(
        configuration: widget.config.product,
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              navigatorKey: _navigatorKey,
              title: widget.config.product.brand.appTitle,
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
                    // Editors show status in their banners. The project list
                    // and Results do not use the floating footer status.
                    if (settings.name == AppRoutes.projects ||
                        settings.name == AppRoutes.projectForm ||
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
      ),
    );
  }
}
