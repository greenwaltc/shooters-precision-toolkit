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
    this.rangeOnly = true,
  });

  final (int, int) rowBounds;
  final bool hasSelectingPosition;
  final bool rangeOnly;
}

/// Clipboard helpers for the ANOMR matrix grid.
///
/// Browser paste uses native clipboard events so external spreadsheet content
/// is available without a clipboard-read permission prompt.
class MatrixGridClipboard {
  MatrixGridClipboard._();

  static const _rangeField = 'range';

  static Future<void> copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      // Browsers use their native copy event if programmatic access is denied.
    }
  }

  /// Reads clipboard text for paste.
  ///
  /// Web uses native paste events instead of requesting clipboard permission.
  /// Other platforms read the system clipboard, including external app copies.
  static Future<String?> readText() async {
    if (kIsWeb) {
      return null;
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
    return null;
  }

  /// Copy column titles followed by the selected rectangle in display order,
  /// including read-only columns. Hidden storage indexes are excluded.
  static String? copyTextForSelection(PlutoGridStateManager manager) {
    final current = manager.currentCellPosition;
    if (current?.rowIdx == null) return null;
    final columns = manager.columnIndexesByShowFrozen;
    String headers(int start, int end) => [
      for (var i = start; i <= end; i++) manager.refColumns[columns[i]].title,
    ].join('\t');
    String rowText(PlutoRow row, int start, int end) => [
      for (var i = start; i <= end; i++)
        row.cells[manager.refColumns[columns[i]].field]?.value?.toString() ??
            '',
    ].join('\t');
    if (manager.selectingMode.isRow &&
        manager.currentSelectingRows.isNotEmpty) {
      final selected = manager.currentSelectingRows.toSet();
      final rows = manager.refRows
          .where(selected.contains)
          .map((row) => rowText(row, 0, columns.length - 1))
          .join('\n');
      return '${headers(0, columns.length - 1)}\n$rows';
    }
    final end = manager.currentSelectingPosition ?? current!;
    final colStart = math.min(current!.columnIdx!, end.columnIdx!);
    final colEnd = math.max(current.columnIdx!, end.columnIdx!);
    final bounds = _selectedRowBounds(manager)!;
    return [
      headers(colStart, colEnd),
      for (var i = bounds.$1; i <= bounds.$2; i++)
        rowText(manager.refRows[i], colStart, colEnd),
    ].join('\n');
  }

  static const pasteRestrictionMessage =
      'Paste is only permitted to the Group Size column.';

  static List<List<String>> parsePaste(String text) {
    var normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Excel adds a final row terminator; it is not an extra empty cell.
    if (normalized.endsWith('\n')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.split('\n').map((row) => row.split('\t')).toList();
  }

  static bool permitsPaste(
    MatrixGridPasteTarget target,
    List<List<String>> rows,
  ) => target.rangeOnly && rows.every((row) => row.length == 1);

  static MatrixGridPasteTarget? capturePasteTarget(
    PlutoGridStateManager manager,
  ) {
    final rowBounds = _selectedRowBounds(manager);
    if (rowBounds == null) {
      return null;
    }

    return MatrixGridPasteTarget(
      rowBounds: rowBounds,
      rangeOnly:
          manager.currentColumn?.field == _rangeField &&
          (manager.currentSelectingPosition == null ||
              manager
                      .refColumns[manager.columnIndexesByShowFrozen[manager
                          .currentSelectingPosition!
                          .columnIdx!]]
                      .field ==
                  _rangeField) &&
          !(manager.selectingMode.isRow &&
              manager.currentSelectingRows.isNotEmpty),
      hasSelectingPosition: manager.currentSelectingPosition != null,
    );
  }

  /// Pastes [textList] into the selected range cells, wrapping when needed.
  static void pasteIntoRangeCells(
    PlutoGridStateManager manager,
    List<List<String>> textList, {
    required MatrixGridPasteTarget target,
  }) {
    if (textList.isEmpty || !permitsPaste(target, textList)) {
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
      manager.changeCellValue(cell, text.isEmpty ? null : text);
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
      return [
        for (var rowIdx = rowStart; rowIdx <= rowEnd; rowIdx += 1) rowIdx,
      ];
    }

    final lastRowIdx = math.min(
      manager.refRows.length - 1,
      rowStart + valueCount - 1,
    );
    return [
      for (var rowIdx = rowStart; rowIdx <= lastRowIdx; rowIdx += 1) rowIdx,
    ];
  }
}

/// Copies the visible selection, including read-only columns.
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
  MatrixGridPasteValuesAction({this.history, this.onRejected, this.canApply});
  final MatrixGridHistoryController? history;
  final VoidCallback? onRejected;
  final bool Function()? canApply;

  bool applyText(
    PlutoGridStateManager manager,
    String? text, {
    MatrixGridPasteTarget? target,
  }) {
    if (text == null || text.isEmpty || canApply?.call() == false) return false;
    target ??= MatrixGridClipboard.capturePasteTarget(manager);
    if (target == null) return false;
    final values = MatrixGridClipboard.parsePaste(text);
    if (!MatrixGridClipboard.permitsPaste(target, values)) {
      onRejected?.call();
      return false;
    }
    // Allow a copied Group Size column to round-trip with its new header.
    if (values.first.single.trim() == 'Group Size') values.removeAt(0);
    if (values.isEmpty) return false;
    if (manager.isEditing == true) manager.setEditing(false);
    history?.beginBatch();
    try {
      MatrixGridClipboard.pasteIntoRangeCells(manager, values, target: target);
    } finally {
      history?.endBatch();
    }
    return true;
  }

  @override
  void execute({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
  }) {
    pasteFromClipboard(stateManager);
  }

  void pasteFromClipboard(PlutoGridStateManager stateManager) {
    // Web paste is handled by the native ClipboardEvent, including external
    // clipboard content. Never substitute a previous in-app copy for it.
    if (kIsWeb) return;
    final target = MatrixGridClipboard.capturePasteTarget(stateManager);
    if (target == null) return;
    MatrixGridClipboard.readText().then(
      (text) => applyText(stateManager, text, target: target),
    );
  }
}
