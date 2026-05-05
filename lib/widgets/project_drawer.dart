// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/project_store.dart';
import '../model/saved_project.dart';
import '../navigation/app_routes.dart';
import '../styles/tokens/app_spacing.dart';
import '../util/format_timestamp.dart';
import 'confirm_delete_project_dialog.dart';

class ProjectDrawer extends StatelessWidget {
  const ProjectDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.folder_open_outlined),
              title: Text('Projects'),
            ),
            const Divider(height: 1.0),
            Expanded(
              child: store.projects.isEmpty
                  ? const Center(child: Text('No projects yet'))
                  : ListView.builder(
                      itemCount: store.projects.length,
                      itemBuilder: (context, index) {
                        final project = store.projects[index];
                        return _ProjectDrawerTile(project: project);
                      },
                    ),
            ),
            Padding(
              padding: AppSpacing.page,
              child: FilledButton.icon(
                onPressed: () => _createProject(context, store),
                icon: const Icon(Icons.add),
                label: const Text('Create New Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProject(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await store.persistSelectedProject();
    await store.createProject();
    navigator.pushNamedAndRemoveUntil(AppRoutes.projectForm, (_) => false);
  }
}

class _ProjectDrawerTile extends StatelessWidget {
  const _ProjectDrawerTile({required this.project});

  final SavedProject project;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final isSelected = store.selectedProject?.id == project.id;

    return ListTile(
      selected: isSelected,
      leading: const Icon(Icons.analytics_outlined),
      title: Text(project.displayName),
      subtitle: Text('Modified ${formatProjectTimestamp(project.updatedAt)}'),
      trailing: IconButton(
        tooltip: 'Delete project',
        onPressed: () => _deleteProject(context, store),
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: () => _openProject(context, store),
    );
  }

  Future<void> _openProject(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await store.persistSelectedProject();
    await store.selectProject(project.id);
    navigator.pushNamedAndRemoveUntil(AppRoutes.anomrMatrix, (_) => false);
  }

  Future<void> _deleteProject(BuildContext context, ProjectStore store) async {
    final navigator = Navigator.of(context);
    final wasSelected = store.selectedProject?.id == project.id;
    final confirmed = await confirmDeleteProject(context, project);

    if (!confirmed || !context.mounted) return;

    await store.deleteProject(project.id);

    if (wasSelected && context.mounted) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.projects, (_) => false);
    }
  }
}
