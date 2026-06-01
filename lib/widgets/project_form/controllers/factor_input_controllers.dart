// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../model/project_form_model.dart';

/// Controller bundle for the three text fields that define one factor.
class FactorInputControllers {
  final factorName = TextEditingController();
  final firstStateName = TextEditingController();
  final secondStateName = TextEditingController();

  /// Adds [listener] to every controller in the bundle.
  void addListener(VoidCallback listener) {
    factorName.addListener(listener);
    firstStateName.addListener(listener);
    secondStateName.addListener(listener);
  }

  /// Hydrates all three controllers from [definition].
  void setValues(FactorDefinition definition) {
    factorName.text = definition.name;
    firstStateName.text = definition.firstState;
    secondStateName.text = definition.secondState;
  }

  /// Clears all visible and hidden factor inputs.
  void clear() {
    factorName.clear();
    firstStateName.clear();
    secondStateName.clear();
  }

  /// Releases all controller resources.
  void dispose() {
    factorName.dispose();
    firstStateName.dispose();
    secondStateName.dispose();
  }
}
