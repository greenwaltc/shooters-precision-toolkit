// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'project_form_model.dart';

/// User-created project plus its setup and matrix entry state.
class SavedProject {
  SavedProject({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.formModel,
    this.setupComplete = false,
    this.randomizeOrder = false,
    this.randomizeSequence,
    Map<String, dynamic>? matrixState,
  }) : matrixState = matrixState ?? {};

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  final ProjectFormModel formModel;

  /// Whether the user has submitted the project setup form and may access
  /// the ANOMR matrix.
  bool setupComplete;

  /// Whether the matrix rows are displayed in a randomized run order.
  bool randomizeOrder;

  /// Persisted randomized row order, expressed as the list of stable sample
  /// (storage) indices in display order. `null` when [randomizeOrder] is off.
  /// Re-generated only when the randomize toggle is switched off and back on.
  List<int>? randomizeSequence;

  final Map<String, dynamic> matrixState;

  /// Display title with a stable fallback for incomplete projects.
  String get displayName {
    final title = formModel.projectTitle.trim();
    return title.isEmpty ? 'Untitled Project' : title;
  }

  /// Rehydrates a project from persisted JSON.
  factory SavedProject.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    final matrixState = json['matrixState'] is Map
        ? Map<String, dynamic>.from(json['matrixState'] as Map)
        : <String, dynamic>{};
    final formModel = json['formModel'] is Map<String, dynamic>
        ? ProjectFormModel.fromJson(json['formModel'] as Map<String, dynamic>)
        : ProjectFormModel();

    return SavedProject(
      id: json['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      createdAt: _dateFromJson(json['createdAt'], now),
      updatedAt: _dateFromJson(json['updatedAt'], now),
      formModel: formModel,
      setupComplete:
          json['setupComplete'] as bool? ??
          (matrixState.isNotEmpty && formModel.isSetupValid),
      randomizeOrder: json['randomizeOrder'] as bool? ?? false,
      randomizeSequence: (json['randomizeSequence'] as List?)
          ?.map((value) => (value as num).toInt())
          .toList(),
      matrixState: matrixState,
    );
  }

  /// Serializes the project for [ProjectStorage].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'setupComplete': setupComplete,
      'randomizeOrder': randomizeOrder,
      'randomizeSequence': randomizeSequence,
      'formModel': formModel.toJson(),
      'matrixState': matrixState,
    };
  }

  /// Marks the project as modified at the current UTC instant.
  void touch() {
    updatedAt = DateTime.now().toUtc();
  }

  static DateTime _dateFromJson(Object? value, DateTime fallback) {
    if (value is! String) return fallback;
    return DateTime.tryParse(value)?.toUtc() ?? fallback;
  }
}
