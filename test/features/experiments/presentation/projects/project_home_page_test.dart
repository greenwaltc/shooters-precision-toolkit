import 'dart:async';
import 'dart:math';

import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/projects/project_home_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/widgets/project_save_status.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
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
  }
}
