import 'dart:async';

import 'package:flutter/material.dart';

/// One sign-out operation shared by every route in an account's workspace.
class WorkspaceSignOut {
  WorkspaceSignOut({required this.flush, required this.signOut});

  final Future<void> Function() flush;
  final Future<void> Function() signOut;
  bool _busy = false;

  Future<void> run(BuildContext context) async {
    if (_busy || !context.mounted) return;
    _busy = true;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final progress = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope<void>(
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
              Expanded(child: Text('Saving and signing out…')),
            ],
          ),
        ),
      ),
    );
    bool saved = false;
    String? errorMessage;

    try {
      // Let active editors commit when focus moves to the modal, then save.
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(navigator.push(progress));
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;
      await flush();
      saved = true;
      await signOut();
      // AuthGate replaces the workspace and its entire navigation stack.
    } catch (_) {
      errorMessage = saved
          ? 'Unable to sign out. Please try again.'
          : 'Your changes could not be saved. You are still signed in. Please try again.';
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
