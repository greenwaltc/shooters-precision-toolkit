// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'matrix_grid_history.dart';

/// Target rows captured before edit mode is cleared for paste.
class MatrixGridPasteTarget {
  const MatrixGridPasteTarget({
    required this.rowBounds,
    required this.hasSelectingPosition,
  });

  final (int, int) rowBounds;
  final bool hasSelectingPosition;
}

/// Clipboard helpers for the ANOMR matrix grid.
///
/// Flutter web shows a permission "Paste" button when [Clipboard.getData] is
/// called, and often cannot read programmatic copies anyway. An in-memory
/// buffer keeps same-session copy/paste working without touching the system
/// clipboard on paste.
class MatrixGridClipboard {
  MatrixGridClipboard._();

  static const _rangeField = 'range';

  static String? _internalBuffer;

  static String? get internalBuffer => _internalBuffer;

  static Future<void> copy(String text) async {
    _internalBuffer = text;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      // setData can fail on web; the in-memory buffer still supports grid paste.
    }
  }

  /// Reads clipboard text for paste.
  ///
  /// On web, only the in-memory buffer is used so paste never triggers the
  /// browser permission prompt from [Clipboard.getData]. On desktop, the
  /// system clipboard is read first so paste from external apps still works.
  static Future<String?> readText() async {
    if (kIsWeb) {
      return _internalBuffer;
    }

    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text != null && text.isNotEmpty) {
        return text;
      }
    } catch (_) {
      // Clipboard read failed.
    }
    return _internalBuffer;
  }

  /// Builds newline-separated clipboard text for the selected range cells only.
  ///
  /// Returns null when there is no active cell/selection to copy from.
  static String? copyTextForSelection(PlutoGridStateManager manager) {
    final rowBounds = _selectedRowBounds(manager);
    if (rowBounds == null) {
      return null;
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

  static MatrixGridPasteTarget? capturePasteTarget(
    PlutoGridStateManager manager,
  ) {
    final rowBounds = _selectedRowBounds(manager);
    if (rowBounds == null) {
      return null;
    }

    return MatrixGridPasteTarget(
      rowBounds: rowBounds,
      hasSelectingPosition: manager.currentSelectingPosition != null,
    );
  }

  /// Pastes [textList] into the selected range cells, wrapping when needed.
  static void pasteIntoRangeCells(
    PlutoGridStateManager manager,
    List<List<String>> textList, {
    required MatrixGridPasteTarget target,
  }) {
    if (textList.isEmpty) {
      return;
    }

    final values = <String>[
      for (final row in textList)
        for (final cell in row) cell,
    ];
    if (values.isEmpty) {
      return;
    }

    final targetRows = _targetRowIndexes(
      manager: manager,
      rowBounds: target.rowBounds,
      valueCount: values.length,
      hasSelectingPosition: target.hasSelectingPosition,
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
    required bool hasSelectingPosition,
  }) {
    final rowStart = rowBounds.$1;
    final rowEnd = rowBounds.$2;
    final selectedRowCount = rowEnd - rowStart + 1;

    if (selectedRowCount > 1 || hasSelectingPosition) {
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
    if (stateManager.currentCell == null) {
      return;
    }

    // Capture selection before edit mode is cleared (that clears selection).
    final text = MatrixGridClipboard.copyTextForSelection(stateManager);
    if (text == null) {
      return;
    }

    if (stateManager.isEditing == true) {
      stateManager.setEditing(false);
    }

    MatrixGridClipboard.copy(text);
  }
}

/// Pastes clipboard values into selected range cells.
class MatrixGridPasteValuesAction extends PlutoGridShortcutAction {
  MatrixGridPasteValuesAction({this.history});

  final MatrixGridHistoryController? history;

  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    if (stateManager.currentCell == null) {
      return;
    }

    // Capture paste target before edit mode is cleared (that clears selection).
    final target = MatrixGridClipboard.capturePasteTarget(stateManager);
    if (target == null) {
      return;
    }

    if (stateManager.isEditing == true) {
      stateManager.setEditing(false);
    }

    void applyPaste(String? text) {
      if (text == null || text.isEmpty) {
        return;
      }

      history?.beginBatch();
      try {
        MatrixGridClipboard.pasteIntoRangeCells(
          stateManager,
          PlutoClipboardTransformation.stringToList(text),
          target: target,
        );
      } finally {
        history?.endBatch();
      }
    }

    if (kIsWeb) {
      applyPaste(MatrixGridClipboard.internalBuffer);
      return;
    }

    MatrixGridClipboard.readText().then(applyPaste);
  }
}
