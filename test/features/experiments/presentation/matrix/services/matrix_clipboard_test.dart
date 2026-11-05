import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/services/matrix_grid_clipboard.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../../support/matrix_test_fixture.dart';

void main() {
  late String clipboard;
  setUp(() {
    clipboard = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboard};
          }
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'mouse drag selects a rectangle and Cmd/Ctrl+C copies all visible columns',
    (tester) async {
      final (_, manager) = await pumpMatrixFixture(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(matrixCell(0, 'row')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(
        tester.getCenter(matrixCell(2, 'range')),
        timeStamp: const Duration(milliseconds: 80),
      );
      await tester.pump();
      // A second update also exercises selection after the drag recognizer wins.
      await gesture.moveTo(
        tester.getCenter(matrixCell(3, 'range')),
        timeStamp: const Duration(milliseconds: 120),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(
        manager.currentCellPosition,
        const PlutoGridCellPosition(columnIdx: 0, rowIdx: 0),
      );
      expect(
        manager.currentSelectingPosition,
        const PlutoGridCellPosition(columnIdx: 4, rowIdx: 3),
      );
      expect(manager.isSelecting, isFalse);
      final selectedBackground = tester.widget<Container>(
        find
            .descendant(
              of: matrixCell(1, 'factor_0'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(selectedBackground.color, manager.style.activatedColor);
      final expected = [
        'Run Order\tReplicate\tFactor 0\tFactor 1\tGroup Size',
        for (var i = 0; i < 4; i++)
          [
            'row',
            'group',
            'factor_0',
            'factor_1',
            'range',
          ].map((field) => '${manager.rows[i].cells[field]!.value}').join('\t'),
      ].join('\n');
      for (final modifier in [
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.controlLeft,
      ]) {
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        expect(clipboard, expected);
      }
      // Start in the editable column and drag backwards with one movement.
      final reverse = await tester.startGesture(
        tester.getCenter(matrixCell(3, 'range')),
        kind: PointerDeviceKind.mouse,
      );
      await reverse.moveTo(tester.getCenter(matrixCell(1, 'group')));
      await tester.pump();
      await reverse.up();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      final rectangle = MatrixGridClipboard.copyTextForSelection(manager)!;
      expect(rectangle.split('\n'), hasLength(4));
      expect(
        rectangle.split('\n').first,
        'Replicate\tFactor 0\tFactor 1\tGroup Size',
      );
      expect(rectangle.split('\n').first.split('\t'), hasLength(4));
      expect(manager.isEditing, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shift+click selection copies all columns in either direction', (
    tester,
  ) async {
    final (_, manager) = await pumpMatrixFixture(tester);
    await tester.tap(matrixCell(0, 'row'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(matrixCell(2, 'range'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    final forward = MatrixGridClipboard.copyTextForSelection(manager)!;
    expect(forward.split('\n'), hasLength(4));
    expect(forward.split('\n').first.split('\t'), hasLength(5));
    expect(
      forward.split('\n').first,
      'Run Order\tReplicate\tFactor 0\tFactor 1\tGroup Size',
    );
    expect(forward.split('\n').skip(1), [
      '1\t1\tLow 0\tLow 1\t1',
      '2\t1\tHigh 0\tLow 1\t3',
      '3\t1\tLow 0\tHigh 1\t2',
    ]);
    manager.setCurrentCell(manager.rows[2].cells['range'], 2);
    manager.setCurrentSelectingPosition(
      cellPosition: const PlutoGridCellPosition(columnIdx: 0, rowIdx: 0),
    );
    expect(MatrixGridClipboard.copyTextForSelection(manager), forward);
  });

  testWidgets(
    'Group Size-only copies include a header and can be pasted back',
    (tester) async {
      final (_, manager) = await pumpMatrixFixture(tester);
      manager.setCurrentSelectingPosition(
        cellPosition: const PlutoGridCellPosition(columnIdx: 4, rowIdx: 1),
      );
      clipboard = MatrixGridClipboard.copyTextForSelection(manager)!;
      expect(clipboard, 'Group Size\n1\n3');
      manager.setCurrentCell(manager.rows[2].cells['range'], 2);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await _paste(tester);
      expect(manager.rows[2].cells['range']!.value, '1');
      expect(manager.rows[3].cells['range']!.value, '3');
      expect(manager.rows[4].cells['range']!.value, '5');
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('whole-row copies include all headers in display order', (
    tester,
  ) async {
    final (_, manager) = await pumpMatrixFixture(tester);
    manager.setSelectingMode(PlutoGridSelectingMode.row);
    manager.setCurrentSelectingRowsByRange(0, 1);
    final rows = MatrixGridClipboard.copyTextForSelection(manager)!.split('\n');
    expect(rows, hasLength(3));
    expect(rows.first, 'Run Order\tReplicate\tFactor 0\tFactor 1\tGroup Size');
    expect(rows[1], startsWith('1\t1\tLow 0\tLow 1\t'));
  });

  testWidgets(
    'multi-column paste is atomic, shows a three-second floating error, and works while editing',
    (tester) async {
      final (store, manager) = await pumpMatrixFixture(tester);
      final original = Map.of(store.selectedProject!.matrixState);
      for (final editing in [false, true]) {
        manager.setCurrentCell(manager.rows.first.cells['range'], 0);
        manager.setEditing(editing);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        clipboard = '100\t200\r\n300\t400\r\n';
        await _paste(tester);
        expect(store.selectedProject!.matrixState, original);
        expect(manager.rows.first.cells['range']!.value, '1');
        final snack = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snack.behavior, SnackBarBehavior.floating);
        expect(snack.duration, const Duration(seconds: 3));
        expect(
          find.text(MatrixGridClipboard.pasteRestrictionMessage),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 2));
        expect(
          find.text(MatrixGridClipboard.pasteRestrictionMessage),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        expect(
          find.text(MatrixGridClipboard.pasteRestrictionMessage),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single-column Excel paste writes Group Size, ignores the final newline, and rejects read-only targets',
    (tester) async {
      final (store, manager) = await pumpMatrixFixture(tester);
      clipboard = '10.25\r\n20.5\r\n';
      await _paste(tester);
      expect(manager.rows[0].cells['range']!.value, '10.25');
      expect(manager.rows[1].cells['range']!.value, '20.5');
      expect(manager.rows[2].cells['range']!.value, '2');
      expect(store.selectedProject!.matrixState['range_2'], '20.5');
      final original = Map.of(store.selectedProject!.matrixState);
      manager.setCurrentCell(manager.rows.first.cells['factor_0'], 0);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      clipboard = '99';
      await _paste(tester);
      expect(store.selectedProject!.matrixState, original);
      expect(
        find.text(MatrixGridClipboard.pasteRestrictionMessage),
        findsOneWidget,
      );
      // Finish the toast timer before tearing down the app.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
    },
  );
}

Future<void> _paste(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}
