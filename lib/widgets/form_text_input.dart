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
