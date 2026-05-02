import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/project_store.dart';
import 'navigation/app_routes.dart';
import 'storage/project_storage.dart';
import 'widgets/anomr_matrix.dart';
import 'widgets/anomr_results_page.dart';
import 'widgets/project_form_page.dart';
import 'widgets/project_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.projectStore});

  final ProjectStore? projectStore;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProjectStore _projectStore;
  late final bool _ownsProjectStore;

  @override
  void initState() {
    super.initState();

    _ownsProjectStore = widget.projectStore == null;
    _projectStore =
        widget.projectStore ??
        ProjectStore(storage: SharedPreferencesProjectStorage());
    unawaited(_projectStore.load());
  }

  @override
  void dispose() {
    if (_ownsProjectStore) {
      _projectStore.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectStore>.value(
      value: _projectStore,
      child: MaterialApp(
        title: 'Shooter\'s Precision Toolkit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.projects,
        routes: {
          AppRoutes.projects: (_) => const ProjectHomePage(),
          AppRoutes.projectForm: (_) => const ProjectFormPage(),
          AppRoutes.anomrMatrix: (_) => const AnomrMatrix(),
          AppRoutes.anomrResults: (_) => const AnomrResultsPage(),
        },
      ),
    );
  }
}
