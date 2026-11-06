import 'dart:math';

import 'package:bramwells_precision_test_kit/features/experiments/data/ephemeral_project_repository.dart';
import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_configuration.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'create a design, enter measurements, view results, and restore the project',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var nextId = 0;
      final repository = EphemeralProjectRepository(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        newId: () => 'journey-${++nextId}',
      );
      addTearDown(repository.dispose);
      final store = ProjectStore(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        draftStorage: InMemoryProjectDraftStorage(),
        repository: repository,
        saveDebounce: Duration.zero,
      );
      addTearDown(store.dispose);
      await store.load();
      await pumpConfiguredWidget(
        tester,
        MyApp(
          clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
          config: testConfig(),
          random: Random(4729),
          projectStore: store,
        ),
      );
      await settle(tester);
      if (kIsWeb) {
        await binding.takeScreenshot('journey-projects');
      }
      await tester.tap(find.text('Create a New Project'));
      await settle(tester);
      final fields = find.byType(TextFormField);
      for (final (index, text) in [
        'Journey fixture',
        'Primer',
        'Standard',
        'Magnum',
      ].indexed) {
        await tester.enterText(fields.at(index), text);
      }
      if (kIsWeb) {
        await binding.takeScreenshot('journey-design');
      }
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await settle(tester);
      expect(find.text('Data matrix'), findsOneWidget);
      if (kIsWeb) {
        await binding.takeScreenshot('journey-matrix');
      }
      final mobile =
          tester.view.physicalSize.width / tester.view.devicePixelRatio < 720;
      for (var row = 0; row < 8; row++) {
        final cell = find.byKey(ValueKey('matrix-cell-$row-range'));
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pump();
        final Finder editor;
        if (mobile) {
          await settle(tester);
          editor = find.descendant(of: cell, matching: find.byType(TextField));
          expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
        } else {
          await tester.tap(cell);
          await tester.pump();
          editor = find.byType(TextField).last;
        }
        await tester.enterText(editor, '1.25');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
      }
      await tester.ensureVisible(find.text('Results'));
      await tester.tap(find.text('Results'));
      await settle(tester);
      expect(
        find.textContaining(RegExp('grand mean', caseSensitive: false)),
        findsWidgets,
      );
      expect(find.textContaining('1.2500'), findsWidgets);
      if (kIsWeb) {
        await binding.takeScreenshot('journey-results');
      }
      await store.saveSelectedProject();
      await pumpConfiguredWidget(tester, const SizedBox.shrink());
      final restored = ProjectStore(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        draftStorage: InMemoryProjectDraftStorage(),
        repository: repository,
        saveDebounce: Duration.zero,
      );
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.projects.single.displayName, 'Journey fixture');
      expect(
        restored.projects.single.matrixState.values.where(
          (value) => value == '1.25',
        ),
        hasLength(8),
      );
    },
  );
}

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);
