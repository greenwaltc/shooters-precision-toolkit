# Code maintenance follow-ups

## Matrix undo and redo

Verify and repair committed grid undo/redo and active-editor history routing for
Cmd+Z, Cmd+Shift+Z, Ctrl+Z, and Ctrl+Y on desktop and web, including Enter/Tab
navigation and focus changes. This is an existing behavior gap, separate from the
coding-standards cleanup. The entry points are `matrix_grid_history.dart` and
`_matrixKeyboardHandler` in `data_matrix_page.dart`.

## Android and Apple build tools

Flutter 3.47.9 builds both Android flavors but warns that the current Gradle,
Android Gradle Plugin, and Kotlin versions will lose support. Schedule a reviewed
toolchain update before upgrading Flutter again. Keep iOS simulator components
matched to the active Xcode version. Flutter also reports existing CocoaPods
scaffolding alongside Swift packages; review that migration separately with
unsigned builds and on-device Firebase sign-in before removing scaffolding.
