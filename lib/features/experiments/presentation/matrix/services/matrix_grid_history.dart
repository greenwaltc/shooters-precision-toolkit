import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../../shared/foundation/behavior_policy.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

// TODO: Repair matrix undo/redo routing; tracking: docs/reference/code_maintenance.md#matrix-undo-and-redo.

/// A single committed range-cell value change.
class MatrixRangeChange {
  /// Records one row's previous and replacement group size. A null value
  /// represents a blank cell.
  const MatrixRangeChange({
    required this.rowIdx,
    required this.previousValue,
    required this.newValue,
  });

  final int rowIdx;
  final String? previousValue;
  final String? newValue;
}

/// One undo/redo step, possibly spanning multiple cells.
class MatrixHistoryEntry {
  /// Copies the changes that belong to one undo or redo step.
  MatrixHistoryEntry(List<MatrixRangeChange> changes)
    : changes = List.unmodifiable(changes);

  /// Wraps one cell change as a complete history step.
  factory MatrixHistoryEntry.single(MatrixRangeChange change) {
    return MatrixHistoryEntry([change]);
  }

  final List<MatrixRangeChange> changes;
}

/// Applies a value at a grid row and optionally records it in history.
typedef MatrixRangeApply =
    void Function(int rowIdx, Object? value, {bool recordHistory});

/// Undo/redo stacks for committed range-cell edits in the matrix grid.
class MatrixGridHistoryController {
  static const _maxEntries = BehaviorPolicy.historyCapacity;

  final List<MatrixHistoryEntry> _undoStack = [];
  final List<MatrixHistoryEntry> _redoStack = [];
  final List<MatrixRangeChange> _batchBuffer = [];
  int _batchDepth = 0;

  /// Drops all recorded edits and resets any active batch.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _batchBuffer.clear();
    _batchDepth = 0;
  }

  /// Starts a batch so multiple edits can be undone together. Batches may be
  /// nested.
  void beginBatch() {
    _batchDepth += 1;
  }

  /// Ends one batch level. The outermost call records the collected changes as
  /// one step.
  void endBatch() {
    if (_batchDepth == 0) {
      return;
    }

    _batchDepth -= 1;
    if (_batchDepth > 0 || _batchBuffer.isEmpty) {
      return;
    }

    _commitUndoEntry(
      MatrixHistoryEntry(List<MatrixRangeChange>.from(_batchBuffer)),
    );
    _batchBuffer.clear();
  }

  /// Records a changed cell or appends it to the active batch.
  ///
  /// Committing a new step clears the redo stack. Unchanged values are ignored.
  void record(MatrixRangeChange change) {
    if (change.previousValue == change.newValue) {
      return;
    }

    if (_batchDepth > 0) {
      _batchBuffer.add(change);
      return;
    }

    _commitUndoEntry(MatrixHistoryEntry.single(change));
  }

  void _commitUndoEntry(MatrixHistoryEntry entry) {
    _undoStack.add(entry);
    if (_undoStack.length > _maxEntries) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Removes and returns the newest undo step, or null when no undo step is
  /// available.
  MatrixHistoryEntry? popUndo() {
    if (_undoStack.isEmpty) {
      return null;
    }
    return _undoStack.removeLast();
  }

  /// Removes and returns the newest redo step, or null when no redo step is
  /// available.
  MatrixHistoryEntry? popRedo() {
    if (_redoStack.isEmpty) {
      return null;
    }
    return _redoStack.removeLast();
  }

  /// Adds [entry] to the redo stack after an undo.
  void pushRedo(MatrixHistoryEntry entry) {
    _redoStack.add(entry);
  }

  /// Adds [entry] back to the undo stack after a redo, within the history
  /// limit.
  void pushUndo(MatrixHistoryEntry entry) {
    _undoStack.add(entry);
    if (_undoStack.length > _maxEntries) {
      _undoStack.removeAt(0);
    }
  }
}

/// Applies a history entry to the grid without recording new history.
void applyMatrixHistoryEntry({
  required MatrixHistoryEntry entry,
  required bool undo,
  required PlutoGridStateManager manager,
  required MatrixRangeApply applyRangeValue,
}) {
  for (final change in entry.changes) {
    applyRangeValue(
      change.rowIdx,
      undo ? change.previousValue : change.newValue,
      recordHistory: false,
    );
  }

  if (entry.changes.isEmpty) {
    return;
  }

  final focusChange = entry.changes.last;
  if (focusChange.rowIdx >= manager.rows.length) {
    return;
  }

  manager.setEditing(false, notify: false);
  manager.setCurrentCell(
    manager.rows[focusChange.rowIdx].cells['range']!,
    focusChange.rowIdx,
  );
  manager.notifyListeners();
}

/// Whether an undo/redo shortcut should fall through to Flutter's built-in
/// text-editing history instead of the grid-level history.
///
/// This is true only when an [EditableText] (a cell actively being typed into,
/// or any other focused text field) currently owns focus AND holds uncommitted
/// edits — i.e. the in-cell text differs from the committed cell value. We must
/// NOT rely on [PlutoGridStateManager.isEditing], because PlutoGrid keeps the
/// grid in editing mode after Enter/Tab navigation even though the freshly
/// focused cell has nothing to undo in-cell.
bool matrixUndoShouldDeferToTextField(PlutoGridStateManager? stateManager) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) {
    return false;
  }

  // No editable text field owns focus → this is a grid/page-level shortcut.
  if (focusContext.findAncestorStateOfType<EditableTextState>() == null) {
    return false;
  }

  final controller = stateManager?.textEditingController;
  if (controller == null) {
    // A text field outside the grid owns focus; leave its history alone.
    return true;
  }

  // A grid cell is being edited. Defer to the cell's text history only when
  // there are uncommitted keystrokes; otherwise treat it as a grid-level undo.
  final committed = stateManager?.currentCell?.value?.toString() ?? '';
  return controller.text != committed;
}

/// Whether [event] is the platform undo shortcut (Cmd+Z / Ctrl+Z).
bool isMatrixUndoShortcut(KeyEvent event) {
  if (event is! KeyDownEvent || event is KeyRepeatEvent) {
    return false;
  }
  if (event.logicalKey != LogicalKeyboardKey.keyZ) {
    return false;
  }

  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isShiftPressed) {
    return false;
  }

  return keyboard.isMetaPressed || keyboard.isControlPressed;
}

/// Whether [event] is the platform redo shortcut (Cmd+Shift+Z / Ctrl+Y).
bool isMatrixRedoShortcut(KeyEvent event) {
  if (event is! KeyDownEvent || event is KeyRepeatEvent) {
    return false;
  }

  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isMetaPressed &&
      keyboard.isShiftPressed &&
      event.logicalKey == LogicalKeyboardKey.keyZ) {
    return true;
  }

  return keyboard.isControlPressed &&
      event.logicalKey == LogicalKeyboardKey.keyY;
}

/// Restores the previous grid-level history entry. Returns true when an entry
/// was applied. In-cell text undo is handled natively by [EditableText]; the
/// caller should defer to it via [matrixUndoShouldDeferToTextField].
bool performMatrixGridUndo({
  required MatrixGridHistoryController history,
  required PlutoGridStateManager? stateManager,
  required MatrixRangeApply applyRangeValue,
}) {
  if (stateManager == null) {
    return false;
  }

  final entry = history.popUndo();
  if (entry == null) {
    return false;
  }

  applyMatrixHistoryEntry(
    entry: entry,
    undo: true,
    manager: stateManager,
    applyRangeValue: applyRangeValue,
  );
  history.pushRedo(entry);
  return true;
}

/// Re-applies the next grid-level history entry. Returns true when an entry was
/// applied. In-cell text redo is handled natively by [EditableText].
bool performMatrixGridRedo({
  required MatrixGridHistoryController history,
  required PlutoGridStateManager? stateManager,
  required MatrixRangeApply applyRangeValue,
}) {
  if (stateManager == null) {
    return false;
  }

  final entry = history.popRedo();
  if (entry == null) {
    return false;
  }

  applyMatrixHistoryEntry(
    entry: entry,
    undo: false,
    manager: stateManager,
    applyRangeValue: applyRangeValue,
  );
  history.pushUndo(entry);
  return true;
}
