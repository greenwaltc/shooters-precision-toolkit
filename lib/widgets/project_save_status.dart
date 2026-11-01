import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/project_store.dart';

enum _ConflictChoice { keepEditing, loadCloud, saveCopy }

/// Save feedback shared by every route in the selected project's workspace.
class ProjectSaveStatus extends StatelessWidget {
  const ProjectSaveStatus({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;
    final state = project == null ? null : store.editStateFor(project.id);
    if (state == null) return const SizedBox.shrink();
    final label = state.draftError != null
        ? 'Unable to save the local draft. Keep this window open.'
        : switch (state.saveState) {
            ProjectSaveState.saved => 'Saved',
            ProjectSaveState.dirty => 'Unsaved changes',
            ProjectSaveState.saving => 'Saving…',
            ProjectSaveState.conflict => 'Save conflict. Your draft is kept.',
            ProjectSaveState.error => 'Unable to save. Your changes are kept.',
          };
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Semantics(liveRegion: true, child: Text(label)),
              if (!state.hasConflict && (state.isDirty || state.error != null))
                TextButton(
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          try {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await store.saveSelectedProject();
                          } catch (_) {
                            // The store retains the error and the draft for retry.
                          }
                        },
                  child: Text(state.error == null ? 'Save' : 'Retry save'),
                ),
              if (state.hasConflict)
                TextButton(
                  onPressed: () => _reviewConflict(context, store, project!.id),
                  child: const Text('Review conflict'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewConflict(
    BuildContext context,
    ProjectStore store,
    String id,
  ) async {
    // In the application shell the status strip is a sibling of the Navigator.
    final dialogContext =
        navigatorKey?.currentState?.overlay?.context ?? context;
    final choice = await showDialog<_ConflictChoice>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Resolve save conflict'),
        content: const Text(
          'Another session changed or deleted this project. Keep editing your '
          'draft, save it as a new project, or discard it and load the latest '
          'received cloud version. Loading the cloud version discards your local edits.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _ConflictChoice.keepEditing),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ConflictChoice.saveCopy),
            child: const Text('Save as a new project'),
          ),
          TextButton(
            onPressed: store.canDiscardDraft(id)
                ? () => Navigator.pop(context, _ConflictChoice.loadCloud)
                : null,
            child: const Text('Discard draft and reload'),
          ),
        ],
      ),
    );
    if (choice == _ConflictChoice.saveCopy && context.mounted) {
      try {
        await store.saveConflictAsNewProject(id);
      } catch (_) {
        // Both the original and failed copy remain recoverable in the store.
      }
      if (context.mounted) {
        navigatorKey?.currentState?.popUntil((route) => route.isFirst);
      }
    } else if (choice == _ConflictChoice.loadCloud && context.mounted) {
      store.discardConflictingDraft(id);
      // Dispose editors that still hold the replaced draft's model/grid state.
      navigatorKey?.currentState?.popUntil((route) => route.isFirst);
    }
  }
}
