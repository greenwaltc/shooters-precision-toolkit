import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/theme/layout/app_layout.dart';
import '../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../project_store.dart';

/// Floats save feedback over the footer without reserving a second footer row.
/// Its presence and height never change the Navigator's available space.
class ProjectWorkspaceFrame extends StatelessWidget {
  /// Wraps workspace content so the save status can be presented where
  /// appropriate.
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
  /// Creates a save indicator that can adapt to a compact layout or appear in a
  /// banner.
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
        ? context.l10n.unableToSaveTheLocalDraftKeepThis
        : switch (state.saveState) {
            ProjectSaveState.saved =>
              store.isProjectCurrent(project!.id)
                  ? context.l10n.saved
                  : context.l10n.cachedData,
            ProjectSaveState.dirty => context.l10n.unsavedChanges,
            ProjectSaveState.saving => context.l10n.saving,
            ProjectSaveState.conflict =>
              context.l10n.saveConflictYourDraftIsKept,
            ProjectSaveState.error =>
              context.l10n.unableToSaveYourChangesAreKept,
          };
    if (compact || inBanner) {
      final hasError = state.error != null || state.draftError != null;
      final actionable = state.hasConflict || state.isDirty || hasError;
      final tooltip = state.hasConflict
          ? context.l10n.saveConflictHint(label)
          : actionable
          ? context.l10n.saveActionHint(
              label,
              hasError ? context.l10n.retrySave : context.l10n.save,
            )
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
            ? context.l10n.reviewConflict
            : hasError
            ? context.l10n.retrySave
            : label;
        return Semantics(
          liveRegion: true,
          child: Tooltip(
            message: tooltip,
            child: TextButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            children: [
              Semantics(liveRegion: true, child: Text(label)),
              if (!state.hasConflict && (state.isDirty || state.error != null))
                TextButton(
                  onPressed: state.isSaving ? null : () => _save(store),
                  child: Text(
                    state.error == null
                        ? context.l10n.save
                        : context.l10n.retrySave,
                  ),
                ),
              if (state.hasConflict)
                TextButton(
                  onPressed: () => _reviewConflict(context, store, project!.id),
                  child: Text(context.l10n.reviewConflict),
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
        title: Text(context.l10n.resolveSaveConflict),
        content: Text(
          context.l10n.anotherSessionChangedOrDeletedThisProjectKeep,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _ConflictChoice.keepEditing),
            child: Text(context.l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ConflictChoice.saveCopy),
            child: Text(context.l10n.saveAsANewProject),
          ),
          TextButton(
            onPressed: store.canDiscardDraft(id)
                ? () => Navigator.pop(context, _ConflictChoice.loadCloud)
                : null,
            child: Text(context.l10n.discardDraftAndReload),
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
