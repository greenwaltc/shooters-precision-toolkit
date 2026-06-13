// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

/// Clipboard helpers for the ANOMR matrix grid.
///
/// Flutter web often cannot read the system clipboard after an in-app copy,
/// so an in-memory buffer keeps same-session copy/paste working.
class MatrixGridClipboard {
  MatrixGridClipboard._();

  static const _rangeField = 'range';

  static String? _internalBuffer;

  static Future<void> copy(String text) async {
    _internalBuffer = text;
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> readText() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text != null && text.isNotEmpty) {
        return text;
      }
    } catch (_) {
      // Web clipboard reads can fail even during keyboard shortcuts.
    }
    return _internalBuffer;
  }

  /// Builds tab/newline clipboard text for the selected range cells only.
  static String copyTextForSelection(PlutoGridStateManager manager) {
    final rowBounds = _selectedRowBounds(manager);
    if (rowBounds == null) {
      return '';
    }

    final rowStart = rowBounds.$1;
    final rowEnd = rowBounds.$2;
    final rows = <String>[];

    for (var rowIdx = rowStart; rowIdx <= rowEnd; rowIdx += 1) {
      final value = manager.refRows[rowIdx].cells[_rangeField]!.value;
      rows.add(value?.toString() ?? '');
    }

    return rows.join('\n');
  }

  /// Pastes [textList] into the selected range cells, wrapping when needed.
  static void pasteIntoRangeCells(
    PlutoGridStateManager manager,
    List<List<String>> textList,
  ) {
    if (manager.currentCellPosition == null || textList.isEmpty) {
      return;
    }

    final values = <String>[
      for (final row in textList)
        for (final cell in row) cell,
    ];
    if (values.isEmpty) {
      return;
    }

    final rowBounds = _selectedRowBounds(manager);
    if (rowBounds == null) {
      return;
    }

    final targetRows = _targetRowIndexes(
      manager: manager,
      rowBounds: rowBounds,
      valueCount: values.length,
    );
    if (targetRows.isEmpty) {
      return;
    }

    var valueIdx = 0;
    for (final rowIdx in targetRows) {
      if (rowIdx > manager.refRows.length - 1) {
        break;
      }

      if (valueIdx > values.length - 1) {
        valueIdx = 0;
      }

      final text = values[valueIdx];
      valueIdx += 1;

      final cell = manager.refRows[rowIdx].cells[_rangeField]!;
      manager.changeCellValue(
        cell,
        text.isEmpty ? null : text,
      );
    }
  }

  static (int, int)? _selectedRowBounds(PlutoGridStateManager manager) {
    final current = manager.currentCellPosition;
    if (current?.rowIdx == null) {
      return null;
    }

    final selecting = manager.currentSelectingPosition;
    if (selecting?.rowIdx == null) {
      return (current!.rowIdx!, current.rowIdx!);
    }

    return (
      math.min(current!.rowIdx!, selecting!.rowIdx!),
      math.max(current.rowIdx!, selecting.rowIdx!),
    );
  }

  static List<int> _targetRowIndexes({
    required PlutoGridStateManager manager,
    required (int, int) rowBounds,
    required int valueCount,
  }) {
    final rowStart = rowBounds.$1;
    final rowEnd = rowBounds.$2;
    final selectedRowCount = rowEnd - rowStart + 1;

    if (selectedRowCount > 1 || manager.currentSelectingPosition != null) {
      return [for (var rowIdx = rowStart; rowIdx <= rowEnd; rowIdx += 1) rowIdx];
    }

    final lastRowIdx = math.min(
      manager.refRows.length - 1,
      rowStart + valueCount - 1,
    );
    return [for (var rowIdx = rowStart; rowIdx <= lastRowIdx; rowIdx += 1) rowIdx];
  }
}

/// Copies selected range values to the clipboard.
class MatrixGridCopyValuesAction extends PlutoGridShortcutAction {
  const MatrixGridCopyValuesAction();

  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    if (stateManager.isEditing == true) {
      stateManager.setEditing(false);
    }

    final text = MatrixGridClipboard.copyTextForSelection(stateManager);
    if (text.isEmpty) {
      return;
    }

    MatrixGridClipboard.copy(text);
  }
}

/// Pastes clipboard values into selected range cells.
class MatrixGridPasteValuesAction extends PlutoGridShortcutAction {
  const MatrixGridPasteValuesAction();

  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    if (stateManager.currentCell == null) {
      return;
    }

    if (stateManager.isEditing == true) {
      stateManager.setEditing(false);
    }

    MatrixGridClipboard.readText().then((text) {
      if (text == null || text.isEmpty) {
        return;
      }

      MatrixGridClipboard.pasteIntoRangeCells(
        stateManager,
        PlutoClipboardTransformation.stringToList(text),
      );
    });
  }
}
