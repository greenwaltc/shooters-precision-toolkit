// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../controllers/factor_input_controllers.dart';

/// Validation rules shared by the project setup form fields.
class ProjectFormValidator {
  const ProjectFormValidator._();

  /// Requires a non-empty value after trimming whitespace.
  static String? requiredField(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  /// Ensures factor names are present and unique among visible factors.
  static String? factorName({
    required int index,
    required String? value,
    required List<FactorInputControllers> controllers,
    required int factorCount,
  }) {
    final requiredError = requiredField(value, 'Factor name is required.');
    if (requiredError != null) return requiredError;

    return _hasDuplicateName(index, value!, controllers, factorCount)
        ? 'Each factor name must be unique.'
        : null;
  }

  /// Ensures paired factor-state names are present and different.
  static String? factorState({
    required String? value,
    required TextEditingController comparedController,
  }) {
    final requiredError = requiredField(value, 'Factor state is required.');
    if (requiredError != null) return requiredError;

    final normalizedValue = value!.trim().toLowerCase();
    final comparedValue = comparedController.text.trim().toLowerCase();
    return normalizedValue == comparedValue
        ? 'Factor states must be different.'
        : null;
  }

  static bool _hasDuplicateName(
    int index,
    String value,
    List<FactorInputControllers> controllers,
    int factorCount,
  ) {
    final normalizedValue = value.trim().toLowerCase();
    return controllers.take(factorCount).indexed.any((entry) {
      final otherIndex = entry.$1;
      final otherValue = entry.$2.factorName.text.trim().toLowerCase();
      return otherIndex != index && otherValue == normalizedValue;
    });
  }
}
