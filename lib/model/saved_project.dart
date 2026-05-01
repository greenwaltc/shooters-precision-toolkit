import 'project_form_model.dart';

class SavedProject {
  SavedProject({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.formModel,
    Map<String, dynamic>? matrixState,
  }) : matrixState = matrixState ?? {};

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  final ProjectFormModel formModel;
  final Map<String, dynamic> matrixState;

  String get displayName {
    final title = formModel.projectTitle.trim();
    return title.isEmpty ? 'Untitled Project' : title;
  }

  factory SavedProject.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();

    return SavedProject(
      id: json['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      createdAt: _dateFromJson(json['createdAt'], now),
      updatedAt: _dateFromJson(json['updatedAt'], now),
      formModel: json['formModel'] is Map<String, dynamic>
          ? ProjectFormModel.fromJson(json['formModel'] as Map<String, dynamic>)
          : ProjectFormModel(),
      matrixState: json['matrixState'] is Map
          ? Map<String, dynamic>.from(json['matrixState'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
