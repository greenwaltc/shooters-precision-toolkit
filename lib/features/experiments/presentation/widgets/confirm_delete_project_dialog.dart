import 'package:flutter/material.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../saved_project.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Shows a confirmation dialog for deleting [project].
///
/// Returns true only when the user confirms. Dismissing the dialog returns
/// false.
Future<bool> confirmDeleteProject(
  BuildContext context,
  SavedProject project,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(context.l10n.deleteProject),
            content: Text(
              context.l10n.deleteProjectMessage(project.displayName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.delete),
              ),
            ],
          );
        },
      ) ??
      false;
}
