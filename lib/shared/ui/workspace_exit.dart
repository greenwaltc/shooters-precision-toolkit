import 'package:flutter/widgets.dart';

/// Application supplies the session exit operation; chrome owns only rendering.
abstract interface class WorkspaceExit {
  Future<void> run(BuildContext context);
}
