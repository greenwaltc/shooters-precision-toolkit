// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../config/project_configuration.dart';
import '../styles/layout/app_viewport.dart';
import '../styles/tokens/app_spacing.dart';

/// Slim copyright notice pinned to the bottom of every page.
///
/// Designed to be used as a [Scaffold.bottomNavigationBar] so it sits below
/// the page body without participating in the body's scroll or layout flow.
/// This is also the single owner of bottom system-inset clearance (taskbar /
/// gesture bar) so page bodies do not pad a second time above the footer.
class AppCopyrightFooter extends StatelessWidget {
  const AppCopyrightFooter({super.key});

  /// Single source of truth for the user-facing copyright line.
  static String get noticeText =>
      ProjectConfiguration.current.brand.copyrightNotice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: AppViewport.footerTextScaler(context),
        ),
        child: SafeArea(
          top: false,
          minimum: AppViewport.needsWebBottomClearance
              ? const EdgeInsets.only(bottom: AppViewport.webMinimumBottomInset)
              : EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              noticeText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
