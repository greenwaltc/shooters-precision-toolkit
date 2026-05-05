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
