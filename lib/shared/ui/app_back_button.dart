// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

/// Shared leading "back" control used by app-bar driven pages.
///
/// Centralizes the icon and styling so every page that offers a backward
/// navigation affordance (results, matrix, etc.) looks and behaves the same.
/// Callers provide [onPressed] because the destination differs per page
/// (popping vs. routing to a specific page).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed, this.tooltip});

  /// Invoked when the user taps the control.
  final VoidCallback onPressed;

  /// Optional tooltip describing the destination.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
