// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

/// Builds the standard [InputDecoration] for the app's text fields.
///
/// Visual configuration (radii, border colors, fill) lives in the
/// `InputDecorationTheme` registered on [ThemeData] — this helper only
/// provides the per-field details: label, hint, prefix icon, and the
/// optional clear button.
InputDecoration buildAppTextFieldDecoration({
  required String labelText,
  String hintText = '',
  Icon? prefixIcon,
  TextEditingController? controller,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        if (controller != null) controller.clear();
      },
    ),
  );
}
