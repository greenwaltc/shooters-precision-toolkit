// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import 'product_configuration.dart';
import 'theme/layout/app_viewport.dart';
import 'theme/tokens/app_colors.dart';

/// Slim copyright notice pinned to the bottom of every page.
///
/// Designed to be used as a [Scaffold.bottomNavigationBar] so it sits below
/// the page body without participating in the body's scroll or layout flow.
/// This is also the single owner of bottom system-inset clearance (taskbar /
/// gesture bar) so page bodies do not pad a second time above the footer.
class AppCopyrightFooter extends StatelessWidget {
  /// Creates the one-line copyright footer.
  const AppCopyrightFooter({super.key});

  /// Single source of truth for the user-facing copyright line.
  static String get noticeText => BrandConfiguration.defaults.copyrightNotice;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.copyrightBackground,
    child: SafeArea(top: false, child: _noticeLine(context)),
  );

  Widget _noticeLine(BuildContext context) => Tooltip(
    message: noticeText,
    excludeFromSemantics: true,
    child: Align(
      alignment: Alignment.center,
      heightFactor: 1,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          noticeText,
          maxLines: 1,
          softWrap: false,
          textScaler: AppViewport.footerTextScaler(context),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.copyrightForeground),
        ),
      ),
    ),
  );
}
