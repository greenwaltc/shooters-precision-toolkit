import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/domain/project_file_codec.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/data_matrix_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/projects/project_home_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/widgets/project_save_status.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/file_loader.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/file_saver.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/test_configuration.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets('Projects clones in place without footer status at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final clock = Clock.fixed(DateTime.utc(2026, 11, 4));
      final repository = FakeProjectRepository();
      final store = ProjectStore(
        repository: repository,
        draftStorage: InMemoryProjectDraftStorage(),
        clock: clock,
      );
      addTearDown(store.dispose);
      await store.load();
      final original = await store.createProject();
      original.formModel.setProjectTitle('Precision trial');
      await store.saveSelectedProject();
      await pumpConfiguredWidget(
        tester,
        MyApp(
          config: testConfig(),
          random: Random(4729),
          clock: clock,
          projectStore: store,
        ),
      );
      Future<void> settle() => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await settle();
      expect(find.byType(ProjectSaveStatus), findsNothing);

      final clone = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Clone project',
      );
      expect(
        tester.getCenter(clone).dx,
        greaterThan(tester.getCenter(find.byIcon(Icons.delete_outline)).dx),
      );
      final release = Completer<void>();
      repository.saveBarrier = release.future;
      await tester.tap(clone);
      await tester.pump();
      expect(tester.widget<IconButton>(clone).onPressed, isNull);
      expect(find.text('Clone of Precision trial'), findsNothing);

      release.complete();
      await settle();
      expect(find.byType(ProjectHomePage), findsOneWidget);
      expect(find.text('Clone of Precision trial'), findsOneWidget);
      expect(find.text('Precision trial'), findsOneWidget);
      expect(store.selectedProject, same(original));
      expect(find.byType(ProjectSaveStatus), findsNothing);
      expect(tester.takeException(), isNull);
      await pumpConfiguredWidget(tester, const SizedBox.shrink());
    });

    testWidgets('project file round trip keeps the original at $size', (
      tester,
    ) async {
      final (store, files) = await _openWorkspace(
        tester,
        size: size,
        seedProject: true,
      );
      final original = store.projects.single;
      final import = find.text('Import');
      expect(
        tester.getCenter(import).dx,
        lessThan(tester.getCenter(find.text('Create a New Project')).dx),
      );
      await tester.tap(find.text('Portable trial'));
      await tester.pumpAndSettle();

      final export = find.text('Export');
      expect(
        tester.getCenter(find.text('Clear')).dx,
        lessThan(tester.getCenter(export).dx),
      );
      expect(
        tester.getCenter(export).dx,
        lessThan(tester.getCenter(find.text('Results')).dx),
      );
      await tester.tap(export);
      await tester.pumpAndSettle();
      expect(files.name, 'project-Portable-trial.json');
      expect(find.text('Project file ready.'), findsOneWidget);
      final snapshot = ProjectFileCodec.decode(files.bytes!);
      expect(snapshot.matrixState['range_0'], '1.25');
      expect(snapshot.randomizeSequence, original.randomizeSequence);

      Navigator.of(tester.element(find.byType(AnomrMatrix))).pop();
      await tester.pumpAndSettle();
      final release = Completer<void>();
      (store.repository as FakeProjectRepository).saveBarrier = release.future;
      await tester.tap(import);
      await tester.pump();
      expect(find.text('Importing…'), findsOneWidget);
      expect(store.projects, hasLength(1));
      release.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProjectHomePage), findsOneWidget);
      expect(find.text('Project imported.'), findsOneWidget);
      expect(find.text('Portable trial'), findsNWidgets(2));
      expect(store.projects, hasLength(2));
      expect(store.selectedProject, same(original));
      final imported = store.projects.singleWhere(
        (entry) => entry.id != original.id,
      );
      expect(imported.formModel.toJson(), original.formModel.toJson());
      expect(imported.matrixState, original.matrixState);
      expect(imported.randomizeSequence, original.randomizeSequence);
      expect(store.revisionFor(imported.id), 1);
      expect(tester.takeException(), isNull);
      await pumpConfiguredWidget(tester, const SizedBox.shrink());
    });
  }

  testWidgets('an empty workspace can reject an invalid or unsupported file', (
    tester,
  ) async {
    final (store, files) = await _openWorkspace(
      tester,
      size: const Size(390, 844),
      seedProject: false,
    );
    final import = find.text('Import');
    await tester.tap(import);
    await tester.pumpAndSettle();
    expect(store.projects, isEmpty);
    expect(find.byType(SnackBar), findsNothing);

    files.bytes = utf8.encode('{invalid');
    await tester.tap(import);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This file is not a valid project JSON'),
      findsOneWidget,
    );
    expect(store.projects, isEmpty);

    ScaffoldMessenger.of(tester.element(import)).removeCurrentSnackBar();
    files.bytes = utf8.encode(
      jsonEncode({'schemaVersion': ProjectFileCodec.supportedVersion + 1}),
    );
    await tester.tap(import);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This file uses project format'),
      findsOneWidget,
    );
    expect(store.projects, isEmpty);
    expect(tester.takeException(), isNull);
    await pumpConfiguredWidget(tester, const SizedBox.shrink());
  });
}

Future<(ProjectStore, _FakeProjectFiles)> _openWorkspace(
  WidgetTester tester, {
  required Size size,
  required bool seedProject,
}) async {
  rootBundle.clear();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final clock = Clock.fixed(DateTime.utc(2026, 11, 4));
  final repository = FakeProjectRepository();
  final store = ProjectStore(
    repository: repository,
    draftStorage: InMemoryProjectDraftStorage(),
    clock: clock,
  );
  addTearDown(repository.dispose);
  addTearDown(store.dispose);
  await store.load();
  if (seedProject) {
    final project = await store.createProject();
    project.formModel
      ..setProjectTitle('Portable trial')
      ..setFactorDefinition(
        index: 0,
        name: 'Primer',
        firstState: 'A',
        secondState: 'B',
      );
    expect(await store.completeProjectSetup(), isTrue);
    final count = project.formModel.sampleSizeOption.totalSamples;
    project.randomizeOrder = true;
    project.randomizeSequence = List.generate(
      count,
      (index) => count - 1 - index,
    );
    project.matrixState['range_0'] = '1.25';
    await store.saveSelectedProject();
  }
  final files = _FakeProjectFiles();
  await pumpConfiguredWidget(
    tester,
    MyApp(
      config: testConfig(),
      random: Random(4729),
      clock: clock,
      projectStore: store,
      fileLoader: files,
      fileSaver: files,
    ),
  );
  await tester.pumpAndSettle();
  return (store, files);
}

class _FakeProjectFiles implements FileLoader, FileSaver {
  Uint8List? bytes;
  String? name;

  @override
  Future<Uint8List?> load({
    required String title,
    required String extension,
    required int maxBytes,
  }) async => bytes;

  @override
  Future<String?> save({
    required String title,
    required String name,
    required Uint8List bytes,
    required String extension,
  }) async {
    this.name = name;
    this.bytes = bytes;
    return name;
  }
}
