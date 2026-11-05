import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../shared/ui/app_copyright_footer.dart';
import '../project_store.dart';
import 'project_save_status.dart';

/// Workspace composes save feedback; the shared credit component knows no store.
class WorkspaceFooter extends StatelessWidget {
  /// Creates a workspace footer with an optional save-status display.
  const WorkspaceFooter({super.key, this.showSaveStatus = true});
  final bool showSaveStatus;
  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ProjectStore?>()?.selectedProject;
    return AppCopyrightFooter(
      showSaveStatus: showSaveStatus,
      status: selected == null ? null : const ProjectSaveStatus(compact: true),
    );
  }
}
