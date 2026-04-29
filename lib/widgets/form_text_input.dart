import 'package:flutter/material.dart';

InputDecoration buildTextInputDecoration({
  required String labelText,
  String hintText = '',
  Icon? prefixIcon,
  TextEditingController? controller
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    // Prefix and Suffix Icons
    prefixIcon: prefixIcon,
    suffixIcon: IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        if (controller != null) controller.clear();
      },
    ),
    // Standard Border
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
    // Border when the field is NOT focused
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.grey, width: 1.5),
    ),
    // Border when the user is typing
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
    ),
    // Border when there is a validation error
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    // Background filling
    filled: true,
    fillColor: Colors.grey[50],
  );
}
