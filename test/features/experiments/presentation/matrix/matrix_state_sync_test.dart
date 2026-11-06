import 'dart:math';

import 'package:bramwells_precision_test_kit/features/experiments/api/project_repository.dart';
import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/data_matrix_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/services/matrix_grid_data_builder.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/saved_project.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/matrix_test_fixture.dart';
import '../../../../support/test_configuration.dart';

void main() {
  for (final mobile in [false, true]) {
    testWidgets(
      'tapping a read-only range takes over on ${mobile ? 'mobile' : 'desktop'}',
      (tester) async {
        final (store, project, repository) = await _openSharedProject(
          tester,
          mobile ? const Size(390, 844) : const Size(1440, 900),
          setupComplete: true,
        );
        final cell = matrixCell(0, 'range');
        PlutoGridStateManager grid() =>
            tester.state<PlutoGridState>(find.byType(PlutoGrid)).stateManager;

        final notice = find.text(AppCopy.english.projectEditingElsewhere);
        expect(notice, findsOneWidget);
        expect(grid().rows.first.cells['range']!.value, '9.5');
        repository.publishRemoteProject(
          CloudProject(
            SavedProject.fromJson(
              project.toJson()..['matrixState'] = {'range_0': '9.75'},
            ),
            3,
            false,
            editorSession: 'other-session',
          ),
        );
        await tester.pumpAndSettle();
        expect(grid().rows.first.cells['range']!.value, '9.75');
        final savedValue = find.descendant(
          of: cell,
          matching: find.text('9.75'),
        );
        expect(
          tester.getCenter(savedValue).dy,
          closeTo(tester.getCenter(cell).dy, 1),
        );
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pumpAndSettle();
        expect(
          store.canEditProject(project.id),
          isTrue,
          reason:
              'Claim pending: ${store.isClaimingEditor(project.id)}. '
              'Draft present: ${store.editStateFor(project.id)?.isDirty}.',
        );
        expect(notice, findsNothing);
        expect(grid().rows.first.cells['range']!.value, '9.75');
        if (mobile) {
          final bounds = tester.getRect(cell);
          await tester.tapAt(Offset(bounds.center.dx, bounds.top + 2));
          await tester.pump();
        }
        final editor = mobile
            ? find.descendant(of: cell, matching: find.byType(TextField))
            : find.byType(TextField);
        expect(tester.widget<TextField>(editor).controller!.text, '9.75');
        expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
        final editable = tester
            .state<EditableTextState>(
              find.descendant(of: editor, matching: find.byType(EditableText)),
            )
            .renderEditable;
        final caret = editable.getLocalRectForCaret(
          const TextPosition(offset: 0),
        );
        expect(
          editable.localToGlobal(caret.center).dy,
          closeTo(tester.getCenter(matrixCell(0, 'row')).dy, 1),
        );
        await tester.enterText(editor, '10');
        await tester.pumpAndSettle();
        expect(store.selectedProject!.matrixState['range_0'], '10');

        final emptyCell = matrixCell(1, 'range');
        if (mobile) {
          await tester.tap(emptyCell);
        } else {
          await tester.tap(emptyCell);
          await tester.pumpAndSettle();
          await tester.tap(emptyCell);
        }
        await tester.pumpAndSettle();
        final emptyEditor = mobile
            ? find.descendant(of: emptyCell, matching: find.byType(TextField))
            : find.byType(TextField);
        expect(tester.widget<TextField>(emptyEditor).controller!.text, isEmpty);
      },
    );
  }

  testWidgets('Enter takes over editing from the selected Group Size cell', (
    tester,
  ) async {
    final (store, project, _) = await _openSharedProject(
      tester,
      const Size(1440, 900),
      setupComplete: true,
    );
    final manager = tester
        .state<PlutoGridState>(find.byType(PlutoGrid))
        .stateManager;
    manager.setCurrentCell(manager.rows.first.cells['range'], 0);
    manager.gridFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(store.canEditProject(project.id), isTrue);
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final keyboard in [false, true]) {
    testWidgets('activating a read-only Test Design field with '
        '${keyboard ? 'Enter' : 'a tap'} transfers control', (tester) async {
      final (store, project, _) = await _openSharedProject(
        tester,
        const Size(390, 844),
        setupComplete: false,
      );
      final notice = find.text(AppCopy.english.projectEditingElsewhere);
      final field = find.byType(TextField).first;
      expect(notice, findsOneWidget);
      expect(tester.widget<TextField>(field).readOnly, isTrue);

      if (keyboard) {
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      } else {
        await tester.tap(field);
      }
      await tester.pumpAndSettle();

      expect(store.canEditProject(project.id), isTrue);
      expect(notice, findsNothing);
      expect(tester.widget<TextField>(field).readOnly, isFalse);
    });
  }

  test('factor states change fastest at the left within each replicate', () {
    final form = ProjectFormModel(
      experimentStructure: ExperimentStructure.threeFactors,
      factorDefinitions: const [
        FactorDefinition(firstState: 'A0', secondState: 'A1'),
        FactorDefinition(firstState: 'B0', secondState: 'B1'),
        FactorDefinition(firstState: 'C0', secondState: 'C1'),
      ],
    );
    final project = SavedProject(
      id: 'three-factor',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      formModel: form,
      matrixState: {'range_4': '2.5', 'range_1': '7.5'},
    );

    final rows = MatrixGridDataBuilder.build(
      formModel: form,
      project: project,
    ).rows;

    expect(
      rows
          .take(9)
          .map(
            (row) => [
              for (final field in [
                'row',
                'group',
                'factor_0',
                'factor_1',
                'factor_2',
              ])
                row.cells[field]!.value,
            ],
          ),
      [
        [1, 1, 'A0', 'B0', 'C0'],
        [2, 1, 'A1', 'B0', 'C0'],
        [3, 1, 'A0', 'B1', 'C0'],
        [4, 1, 'A1', 'B1', 'C0'],
        [5, 1, 'A0', 'B0', 'C1'],
        [6, 1, 'A1', 'B0', 'C1'],
        [7, 1, 'A0', 'B1', 'C1'],
        [8, 1, 'A1', 'B1', 'C1'],
        [9, 2, 'A0', 'B0', 'C0'],
      ],
    );
    expect(rows[1].cells['range']!.value, '2.5');
    expect(rows[4].cells['range']!.value, '7.5');
  });

  testWidgets(
    'reopening a randomized matrix and toggling off restores run order',
    (tester) async {
      final (store, manager) = await pumpMatrixFixture(tester);
      final randomize = find.byType(Switch);
      List<int> storageOrder(PlutoGridStateManager grid) => [
        for (final row in grid.rows) row.cells['storage']!.value as int,
      ];
      final original = storageOrder(manager);
      expect(original.take(4), [0, 2, 1, 3]);

      await tester.tap(randomize);
      await tester.pumpAndSettle();
      final randomized = storageOrder(manager);
      expect(randomized, isNot(original));
      expect(store.selectedProject!.randomizeSequence, randomized);

      Navigator.of(tester.element(find.byType(AnomrMatrix))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clipboard fixture'));
      await tester.pumpAndSettle();
      final reopened = tester
          .state<PlutoGridState>(find.byType(PlutoGrid))
          .stateManager;
      expect(storageOrder(reopened), randomized);

      await tester.tap(randomize);
      await tester.pumpAndSettle();
      expect(storageOrder(reopened), original);
      expect(reopened.rows[1].cells['range']!.value, '3');
      expect(store.selectedProject!.randomizeSequence, isNull);
    },
  );

  test('syncMatrixStateFromRows copies cell values the store was missing', () {
    final project = SavedProject(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      formModel: ProjectFormModel(),
      // Simulate the bug: only the last cell made it into persistence.
      matrixState: {'range_1': '2'},
    );

    final rows = <PlutoRow>[
      PlutoRow(
        cells: {
          'storage': PlutoCell(value: 0),
          'range': PlutoCell(value: '1.5'),
        },
      ),
      PlutoRow(
        cells: {
          'storage': PlutoCell(value: 1),
          'range': PlutoCell(value: '2'),
        },
      ),
      PlutoRow(
        cells: {
          'storage': PlutoCell(value: 2),
          'range': PlutoCell(value: '3'),
        },
      ),
    ];

    final changed = MatrixGridDataBuilder.syncMatrixStateFromRows(
      project: project,
      rows: rows,
    );

    expect(changed, isTrue);
    expect(project.matrixState['range_0'], '1.5');
    expect(project.matrixState['range_1'], '2');
    expect(project.matrixState['range_2'], '3');
  });
}

Future<(ProjectStore, SavedProject, _EditingRepository)> _openSharedProject(
  WidgetTester tester,
  Size size, {
  required bool setupComplete,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final now = DateTime.utc(2026, 11, 5);
  final project = SavedProject(
    id: 'shared-project',
    createdAt: now,
    updatedAt: now,
    setupComplete: setupComplete,
    formModel: ProjectFormModel(
      projectTitle: 'Shared project',
      factorDefinitions: const [
        FactorDefinition(name: 'Factor', firstState: 'A', secondState: 'B'),
      ],
    ),
    matrixState: {'range_0': '9.5'},
  );
  final repository = _EditingRepository()
    ..publishRemoteProject(
      CloudProject(project, 2, false, editorSession: 'other-session'),
    );
  final store = ProjectStore(
    repository: repository,
    draftStorage: InMemoryProjectDraftStorage(),
    clock: Clock.fixed(now),
    saveDebounce: Duration.zero,
  );
  addTearDown(store.dispose);
  await pumpConfiguredWidget(
    tester,
    MyApp(
      clock: Clock.fixed(now),
      config: testConfig(),
      random: Random(4729),
      projectStore: store,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Shared project'));
  await tester.pumpAndSettle();
  return (store, project, repository);
}

class _EditingRepository extends FakeProjectRepository
    implements ProjectEditingRepository {
  @override
  String get editingSessionId => 'local-session';

  @override
  Future<CloudProject> claimEditing(
    String id, {
    required bool allowTakeover,
  }) async {
    final current = remoteProject(id)!;
    if (current.editorSession == editingSessionId ||
        (current.editorSession != null && !allowTakeover)) {
      return current;
    }
    final claim = CloudProject(
      current.project,
      current.revision + 1,
      false,
      editorSession: editingSessionId,
    );
    publishRemoteProject(claim);
    return claim;
  }
}
