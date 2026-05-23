// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'project_form_model.dart';

class SavedProject {
  SavedProject({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.formModel,
    this.setupComplete = false,
    Map<String, dynamic>? matrixState,
  }) : matrixState = matrixState ?? {};

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  final ProjectFormModel formModel;

  /// Whether the user has submitted the project setup form and may access
  /// the ANOMR matrix.
  bool setupComplete;
  final Map<String, dynamic> matrixState;

  String get displayName {
    final title = formModel.projectTitle.trim();
    return title.isEmpty ? 'Untitled Project' : title;
  }

  factory SavedProject.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    final matrixState = json['matrixState'] is Map
        ? Map<String, dynamic>.from(json['matrixState'] as Map)
        : <String, dynamic>{};

    return SavedProject(
      id: json['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      createdAt: _dateFromJson(json['createdAt'], now),
      updatedAt: _dateFromJson(json['updatedAt'], now),
      formModel: json['formModel'] is Map<String, dynamic>
          ? ProjectFormModel.fromJson(json['formModel'] as Map<String, dynamic>)
          : ProjectFormModel(),
      setupComplete:
          json['setupComplete'] as bool? ??
          matrixState.isNotEmpty,
      matrixState: matrixState,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'setupComplete': setupComplete,
      'formModel': formModel.toJson(),
      'matrixState': matrixState,
    };
  }

  void touch() {
    updatedAt = DateTime.now().toUtc();
  }

  static DateTime _dateFromJson(Object? value, DateTime fallback) {
    if (value is! String) return fallback;
    return DateTime.tryParse(value)?.toUtc() ?? fallback;
  }
}
