import 'package:flutter/widgets.dart';

/// Application supplies the session exit operation; chrome owns only rendering.
abstract interface class WorkspaceExit {
  /// Runs the workspace exit flow using [context] for any user interaction.
  Future<void> run(BuildContext context);
}
