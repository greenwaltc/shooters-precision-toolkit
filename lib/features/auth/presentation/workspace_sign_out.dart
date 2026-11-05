import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/l10n/app_copy.dart';
import '../../../shared/ui/workspace_exit.dart';

/// One sign-out operation shared by every route in an account's workspace.
class WorkspaceSignOut implements WorkspaceExit {
  /// Creates a sign-out action that calls [flush] before [signOut].
  WorkspaceSignOut({required this.flush, required this.signOut});

  final Future<void> Function() flush;
  final Future<void> Function() signOut;
  bool _busy = false;

  @override
  Future<void> run(BuildContext context) async {
    if (_busy || !context.mounted) {
      return;
    }
    _busy = true;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final progress = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope<void>(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              ),
              SizedBox(width: 16),
              Expanded(child: Text(context.l10n.savingAndSigningOut)),
            ],
          ),
        ),
      ),
    );
    final copy = context.l10n;
    bool saved = false;
    String? errorMessage;

    try {
      // Let active editors commit when focus moves to the modal, then save.
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(navigator.push(progress));
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) {
        return;
      }
      await flush();
      saved = true;
      await signOut();
      // AuthGate replaces the workspace and its entire navigation stack.
    } catch (_) {
      errorMessage = saved
          ? copy.unableToSignOutPleaseTryAgain
          : copy.yourChangesCouldNotBeSavedYouAre;
    } finally {
      if (navigator.mounted && progress.isActive) {
        navigator.removeRoute(progress);
      }
      _busy = false;
      if (context.mounted && messenger.mounted && errorMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }
}
