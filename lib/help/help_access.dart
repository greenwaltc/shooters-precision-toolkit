// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../styles/layout/app_layout.dart';
import 'help_instructions.dart';

/// App-bar help control shown on narrow viewports where a FAB would crowd
/// the layout.
class HelpInstructionsAppBarAction extends StatelessWidget {
  const HelpInstructionsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Help',
      onPressed: () => showHelpInstructionsSheet(context),
      icon: const Icon(Icons.question_mark_outlined),
    );
  }
}

/// Floating help control shown on wider viewports.
class HelpInstructionsFab extends StatelessWidget {
  const HelpInstructionsFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      tooltip: 'Help',
      onPressed: () => showHelpInstructionsSheet(context),
      child: const Icon(Icons.question_mark_outlined),
    );
  }
}

/// Returns help [AppBar] actions when the current layout is mobile-sized, or
/// when [preferAppBar] is true for pages whose bottom toolbars would conflict
/// with a FAB (e.g. the ANOMR matrix action row).
List<Widget> helpAppBarActionsFor(
  AppLayoutMetrics layout, {
  bool preferAppBar = false,
}) {
  if (layout.isMobile || preferAppBar) {
    return const [HelpInstructionsAppBarAction()];
  }
  return const [];
}

/// Returns a help FAB when the current layout is not mobile-sized and a FAB
/// will not crowd existing bottom actions.
Widget? helpFabFor(AppLayoutMetrics layout, {bool preferAppBar = false}) {
  if (layout.isMobile || preferAppBar) return null;
  return const HelpInstructionsFab();
}

/// Default FAB placement used wherever the help FAB appears.
const FloatingActionButtonLocation helpFabLocation =
    FloatingActionButtonLocation.miniStartFloat;
