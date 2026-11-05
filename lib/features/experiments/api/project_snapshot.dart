import '../../../shared/foundation/json_object.dart';
import 'test_design.dart';

/// A write input is synchronously frozen before an adapter starts asynchronous
/// work. Implementations must never retain the mutable input after this call.
abstract interface class ProjectDocument {
  String get id;
  Map<String, Object?> toJson();
  ProjectSnapshot freeze();
}

/// Immutable application-owned document, independent of widgets and vendor SDKs.
/// Dates are UTC instants; group sizes retain canonical English numeric strings
/// or finite numbers in the user's chosen measurement unit (no conversion).
final class ProjectSnapshot implements ProjectDocument {
  ProjectSnapshot({
    required this.id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.formModel,
    required this.setupComplete,
    required this.randomizeOrder,
    required List<int>? randomizeSequence,
    required Map<String, Object?> matrixState,
  }) : createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc(),
       randomizeSequence = randomizeSequence == null
           ? null
           : List.unmodifiable(randomizeSequence),
       matrixState = Map.unmodifiable(matrixState) {
    if (id.isEmpty || id.contains('/')) {
      throw const FormatException('Invalid project identity.');
    }
    for (final value in matrixState.values) {
      if (value != null &&
          value is! String &&
          (value is! num || !value.isFinite)) {
        throw const FormatException('Invalid matrix value.');
      }
    }
  }

  @override
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TestDesignSnapshot formModel;
  final bool setupComplete;
  final bool randomizeOrder;
  final List<int>? randomizeSequence;
  final Map<String, Object?> matrixState;
  String get displayName => formModel.projectTitle.trim();

  factory ProjectSnapshot.fromJson(Map<String, Object?> json) {
    DateTime instant(String key) {
      final raw = optionalJsonValue<String>(json, key);
      final value = raw == null ? null : DateTime.tryParse(raw);
      if (value == null) {
        throw const FormatException('Invalid project timestamp.');
      }
      return value.toUtc();
    }

    final sequence = optionalJsonValue<List<Object?>>(
      json,
      'randomizeSequence',
    );
    return ProjectSnapshot(
      id: optionalJsonValue<String>(json, 'id') ?? '',
      createdAt: instant('createdAt'),
      updatedAt: instant('updatedAt'),
      formModel: TestDesignSnapshot.fromJson(jsonObject(json['formModel'])),
      setupComplete: optionalJsonValue<bool>(json, 'setupComplete') ?? false,
      randomizeOrder: optionalJsonValue<bool>(json, 'randomizeOrder') ?? false,
      randomizeSequence: sequence?.map((value) {
        if (value is! int || value < 0) {
          throw const FormatException('Invalid row index.');
        }
        return value;
      }).toList(),
      matrixState: Map<String, Object?>.of(jsonObject(json['matrixState'])),
    );
  }

  @override
  ProjectSnapshot freeze() => this;
  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'formModel': formModel.toJson(),
    'setupComplete': setupComplete,
    'randomizeOrder': randomizeOrder,
    'randomizeSequence': randomizeSequence?.toList(),
    'matrixState': Map.of(matrixState),
  };
}

/// Persisted design data. An absent sample choice is represented explicitly;
/// presentation resolves it against the versioned calibration catalog on load.
final class TestDesignSnapshot {
  TestDesignSnapshot({
    required this.projectTitle,
    required this.experimentStructure,
    required this.riskLevel,
    required this.sampleSizeOption,
    required List<FactorDefinition> factorDefinitions,
    required this.imputeMissingData,
  }) : factorDefinitions = List.unmodifiable(factorDefinitions);
  final String projectTitle;
  final ExperimentStructure experimentStructure;
  final RiskLevel riskLevel;
  final SampleSizeOption? sampleSizeOption;
  final List<FactorDefinition> factorDefinitions;
  final bool imputeMissingData;

  factory TestDesignSnapshot.fromJson(Map<String, Object?> json) {
    final option = json['sampleSizeOption'];
    return TestDesignSnapshot(
      projectTitle: optionalJsonValue<String>(json, 'projectTitle') ?? '',
      experimentStructure: ExperimentStructure.fromName(
        optionalJsonValue<String>(json, 'experimentStructure'),
      ),
      riskLevel: RiskLevel.fromName(
        optionalJsonValue<String>(json, 'riskLevel'),
      ),
      sampleSizeOption: option == null
          ? null
          : SampleSizeOption.fromJson(jsonObject(option)),
      factorDefinitions:
          (optionalJsonValue<List<Object?>>(json, 'factorDefinitions') ??
                  const [])
              .map((value) => FactorDefinition.fromJson(jsonObject(value)))
              .toList(),
      imputeMissingData:
          optionalJsonValue<bool>(json, 'imputeMissingData') ?? false,
    );
  }
  Map<String, Object?> toJson() => {
    'projectTitle': projectTitle,
    'experimentStructure': experimentStructure.name,
    'riskLevel': riskLevel.name,
    'sampleSizeOption': sampleSizeOption?.toJson(),
    'factorDefinitions': factorDefinitions
        .map((factor) => factor.toJson())
        .toList(),
    'imputeMissingData': imputeMissingData,
  };
}
