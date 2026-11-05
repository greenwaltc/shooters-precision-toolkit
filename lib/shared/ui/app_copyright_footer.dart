// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import 'app_brand_bar.dart';
import 'product_configuration.dart';
import 'theme/layout/app_layout.dart';
import 'theme/layout/app_viewport.dart';
import 'theme/tokens/app_spacing.dart';

/// Slim copyright notice pinned to the bottom of every page.
///
/// Designed to be used as a [Scaffold.bottomNavigationBar] so it sits below
/// the page body without participating in the body's scroll or layout flow.
/// This is also the single owner of bottom system-inset clearance (taskbar /
/// gesture bar) so page bodies do not pad a second time above the footer.
class AppCopyrightFooter extends StatelessWidget {
  const AppCopyrightFooter({
    super.key,
    this.showSaveStatus = true,
    this.status,
  });

  /// Editors with status in their banner use only the slim copyright line.
  final bool showSaveStatus;
  final Widget? status;

  /// Single source of truth for the user-facing copyright line.
  static String get noticeText => BrandConfiguration.defaults.copyrightNotice;

  @override
  Widget build(BuildContext context) {
    final mobile = AppLayoutMetrics.of(context).isMobile;
    if (mobile && showSaveStatus) {
      return Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(child: _noticeLine(context)),
                  ?status,
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppViewport.footerTextScaler(context)),
        child: SafeArea(
          top: false,
          minimum: AppViewport.needsWebBottomClearance
              ? const EdgeInsets.only(bottom: AppViewport.webMinimumBottomInset)
              : EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppBrandAssets.isMobileLandscapeBanner(context)
                  ? 0
                  : AppSpacing.xs,
            ),
            child: _noticeLine(context),
          ),
        ),
      ),
    );
  }

  Widget _noticeLine(BuildContext context) => Tooltip(
    message: noticeText,
    excludeFromSemantics: true,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          noticeText,
          maxLines: 1,
          softWrap: false,
          textScaler: AppViewport.footerTextScaler(context),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
      ),
    ),
  );
}
