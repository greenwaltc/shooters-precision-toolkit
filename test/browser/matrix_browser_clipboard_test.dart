@TestOn('browser')
library;

import 'package:bramwells_precision_test_kit/widgets/anomr_matrix/services/matrix_grid_clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:web/web.dart' as web;

import '../support/matrix_test_fixture.dart';

void main() {
  testWidgets(
    'browser copies the full selection and validates external paste, including the cell editor',
    (tester) async {
      final errorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        // Browser test runners do not always forward Flutter's error dump.
        // ignore: avoid_print
        print(details.toString());
        errorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = errorHandler);
      final (store, manager) = await pumpMatrixFixture(tester);
      manager.setCurrentCell(manager.rows.first.cells['row'], 0);
      manager.setCurrentSelectingPosition(
        cellPosition: const PlutoGridCellPosition(columnIdx: 4, rowIdx: 2),
      );
      await tester.pumpAndSettle();
      final copyData = web.DataTransfer();
      final copyEvent = _event('copy', copyData);
      web.document.dispatchEvent(copyEvent);
      expect(copyEvent.defaultPrevented, isTrue);
      final copied = copyData.getData('text/plain');
      expect(copied.split('\n'), hasLength(3));
      expect(copied.split('\n').first.split('\t'), hasLength(5));
      // Native clipboard keys must escape Flutter/Pluto's default handlers so
      // the browser can generate real copy/paste events (no permission prompt).
      for (final modifier in [
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.controlLeft,
      ]) {
        await tester.sendKeyDownEvent(modifier);
        expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC), isFalse);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
        expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV), isFalse);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(modifier);
      }
      manager.setCurrentCell(manager.rows.first.cells['range'], 0);
      await tester.pumpAndSettle();
      // External paste must use the event's text, not the previous copied TSV.
      _paste('10.25\r\n20.5\r\n');
      await tester.pumpAndSettle();
      expect(manager.rows[0].cells['range']!.value, '10.25');
      expect(manager.rows[1].cells['range']!.value, '20.5');
      expect(manager.rows[2].cells['range']!.value, '3');
      final original = Map.of(store.selectedProject!.matrixState);
      for (final editing in [false, true]) {
        manager.setEditing(editing);
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV), isFalse);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        _paste('100\t200\n300\t400\n');
        await tester.pumpAndSettle();
        expect(store.selectedProject!.matrixState, original);
        expect(
          find.text(MatrixGridClipboard.pasteRestrictionMessage),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }
      // Other input fields/routes must retain their normal clipboard behavior.
      manager.setEditing(false);
      await tester.tap(find.widgetWithText(FilledButton, 'Contact'));
      await tester.pumpAndSettle();
      final outsidePaste = _event(
        'paste',
        web.DataTransfer()..setData('text/plain', '99'),
      );
      web.document.dispatchEvent(outsidePaste);
      expect(store.selectedProject!.matrixState, original);
      expect(
        find.text(MatrixGridClipboard.pasteRestrictionMessage),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

web.ClipboardEvent _event(String type, web.DataTransfer data) =>
    web.ClipboardEvent(
      type,
      web.ClipboardEventInit(
        clipboardData: data,
        bubbles: true,
        cancelable: true,
      ),
    );

void _paste(String text) {
  final data = web.DataTransfer()..setData('text/plain', text);
  final event = _event('paste', data);
  web.document.dispatchEvent(event);
  expect(event.defaultPrevented, isTrue);
}
