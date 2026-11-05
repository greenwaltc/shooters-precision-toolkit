# Code maintenance follow-ups

## Matrix undo and redo

Verify and repair committed grid undo/redo and active-editor history routing for
Cmd+Z, Cmd+Shift+Z, Ctrl+Z, and Ctrl+Y on desktop and web, including Enter/Tab
navigation and focus changes. This is an existing behavior gap, separate from the
coding-standards cleanup. The entry points are `matrix_grid_history.dart` and
`_matrixKeyboardHandler` in `anomr_matrix.dart`.
