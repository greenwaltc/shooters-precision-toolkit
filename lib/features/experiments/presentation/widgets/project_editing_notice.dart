import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/foundation/app_failure.dart';
import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../project_store.dart';

/// Displays editing availability and claims an unowned project when opened.
class ProjectEditingNotice extends StatefulWidget {
  /// Creates the notice for the selected project [projectId].
  const ProjectEditingNotice({super.key, required this.projectId});

  final String projectId;

  /// Requests editing on behalf of an intentional UI action.
  ///
  /// Returns false if the claim is denied, no longer applies, or a request is
  /// pending. Shows a retry message for a recoverable repository failure.
  static Future<bool> request(
    BuildContext context,
    String projectId, {
    required bool allowTakeover,
  }) async {
    try {
      return await context.read<ProjectStore>().claimProjectEditing(
        projectId,
        allowTakeover: allowTakeover,
      );
    } on AppFailure {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.projectEditingHandoffFailed)),
        );
      }
      return false;
    }
  }

  @override
  State<ProjectEditingNotice> createState() => _ProjectEditingNoticeState();
}

class _ProjectEditingNoticeState extends State<ProjectEditingNotice> {
  String? _autoClaimedProject;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final id = widget.projectId;
    if (store.canEditProject(id)) {
      return const SizedBox.shrink();
    }
    final claiming = store.isClaimingEditor(id);
    final elsewhere = store.isEditingElsewhere(id);
    final hasDraft = store.editStateFor(id)?.isDirty == true;
    final isCurrentRoute = ModalRoute.isCurrentOf(context) ?? true;
    if (isCurrentRoute &&
        !hasDraft &&
        !claiming &&
        _autoClaimedProject != id &&
        store.canClaimUnownedProject(id)) {
      _autoClaimedProject = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.projectId == id &&
            (ModalRoute.isCurrentOf(context) ?? true)) {
          unawaited(
            ProjectEditingNotice.request(context, id, allowTakeover: false),
          );
        }
      });
    }
    final l10n = context.l10n;
    final label = claiming
        ? l10n.projectEditingStarting
        : hasDraft
        ? l10n.projectEditingDraftKept
        : elsewhere
        ? l10n.projectEditingElsewhere
        : l10n.projectEditingReadOnly;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(liveRegion: true, child: Text(label)),
    );
  }
}
