import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/project_store.dart';
import '../styles/layout/app_layout.dart';

/// Floats save feedback over the footer without reserving a second footer row.
/// Its presence and height never change the Navigator's available space.
class ProjectWorkspaceFrame extends StatelessWidget {
  const ProjectWorkspaceFrame({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final status = ProjectSaveStatus(navigatorKey: navigatorKey);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    if (AppLayoutMetrics.of(context).isMobile) {
      return child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          bottom: 4 + bottomInset,
          left: 24,
          right: 24,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: IntrinsicWidth(child: status),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ConflictChoice { keepEditing, loadCloud, saveCopy }

/// Save feedback in a project banner or floating over the workspace footer.
class ProjectSaveStatus extends StatelessWidget {
  const ProjectSaveStatus({
    super.key,
    this.navigatorKey,
    this.compact = false,
    this.inBanner = false,
  });

  final bool compact;
  final bool inBanner;

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final project = store.selectedProject;
    final state = project == null ? null : store.editStateFor(project.id);
    if (state == null) {
      return const SizedBox.shrink();
    }
    final label = state.draftError != null
        ? 'Unable to save the local draft. Keep this window open.'
        : switch (state.saveState) {
            ProjectSaveState.saved => 'Saved',
            ProjectSaveState.dirty => 'Unsaved changes',
            ProjectSaveState.saving => 'Saving…',
            ProjectSaveState.conflict => 'Save conflict. Your draft is kept.',
            ProjectSaveState.error => 'Unable to save. Your changes are kept.',
          };
    if (compact || inBanner) {
      final hasError = state.error != null || state.draftError != null;
      final actionable = state.hasConflict || state.isDirty || hasError;
      final tooltip = state.hasConflict
          ? '$label Review conflict'
          : actionable
          ? '$label ${hasError ? "Retry save" : "Save"}'
          : label;
      final color = !hasError
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.error;
      final icon = state.hasConflict || hasError
          ? Icons.cloud_off_outlined
          : state.isSaving
          ? Icons.sync
          : state.isDirty
          ? Icons.cloud_upload_outlined
          : Icons.cloud_done_outlined;
      final VoidCallback? onPressed = !actionable || state.isSaving
          ? null
          : () => state.hasConflict
                ? _reviewConflict(context, store, project!.id)
                : _save(store);
      if (inBanner && !compact) {
        final shortLabel = state.hasConflict
            ? 'Review conflict'
            : hasError
            ? 'Retry save'
            : label;
        return Semantics(
          liveRegion: true,
          child: Tooltip(
            message: tooltip,
            child: TextButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(shortLabel, maxLines: 1),
              style: TextButton.styleFrom(
                foregroundColor: color,
                disabledForegroundColor: color,
                backgroundColor: color.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        );
      }
      return Semantics(
        liveRegion: true,
        child: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: tooltip,
            color: color,
            disabledColor: inBanner ? color : null,
            icon: Icon(icon),
            onPressed: onPressed,
          ),
        ),
      );
    }
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation:
          MediaQuery.sizeOf(context).width >= AppLayoutMetrics.mobileBreakpoint
          ? 3
          : 0,
      borderRadius:
          MediaQuery.sizeOf(context).width >= AppLayoutMetrics.mobileBreakpoint
          ? BorderRadius.circular(12)
          : null,
      child: SafeArea(
        top: false,
        bottom:
            MediaQuery.sizeOf(context).width <
            AppLayoutMetrics.mobileBreakpoint,
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
                  onPressed: state.isSaving ? null : () => _save(store),
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

  Future<void> _save(ProjectStore store) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await store.saveSelectedProject();
    } catch (_) {
      // The store retains the error and draft for retry.
    }
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
        (navigatorKey?.currentState ?? Navigator.maybeOf(context))?.popUntil(
          (route) => route.isFirst,
        );
      }
    } else if (choice == _ConflictChoice.loadCloud && context.mounted) {
      store.discardConflictingDraft(id);
      // Dispose editors that still hold the replaced draft's model/grid state.
      (navigatorKey?.currentState ?? Navigator.maybeOf(context))?.popUntil(
        (route) => route.isFirst,
      );
    }
  }
}
