// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../styles/components/app_text_field_decoration.dart';

/// Backwards-compatible re-export so existing callers keep compiling.
///
/// Prefer importing `app_text_field_decoration.dart` directly in new code.
InputDecoration buildTextInputDecoration({
  required String labelText,
  String hintText = '',
  Icon? prefixIcon,
  TextEditingController? controller,
}) {
  return buildAppTextFieldDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    controller: controller,
  );
}
