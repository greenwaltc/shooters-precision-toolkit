import 'dart:convert';
import 'dart:typed_data';

import '../../../shared/foundation/behavior_policy.dart';
import '../../../shared/foundation/json_object.dart';
import '../api/project_snapshot.dart';
import 'project_file_version.dart';
import 'range_value_parser.dart';
import 'sample_size_catalog.dart';

/// Reports a portable file written with a version this app cannot read.
final class UnsupportedProjectFileVersion implements Exception {
  /// Identifies the version found in the file.
  const UnsupportedProjectFileVersion(this.version);

  final int version;
}

/// Reads and writes the current version of the portable UTF-8 project format.
abstract final class ProjectFileCodec {
  /// Version used for both new exports and import validation.
  static const supportedVersion = projectFileSchemaVersion;

  /// Extension for portable project files.
  static const extension = 'json';

  // Storage limits also enforced by the project write rules.
  static const _factorSlots = 4;
  static const _maxFactorLabelLength = 120;
  static const _maxMatrixEntries = 4096;
  static final _rangeKey = RegExp(r'^range_(0|[1-9][0-9]*)$');

  /// Encodes the project's current state without cloud revision metadata.
  ///
  /// Throws [FormatException] if the project cannot fit in a valid file.
  static Uint8List encode(ProjectDocument project) {
    final json = project.freeze().toJson();
    _parseProject(json);
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert({'schemaVersion': supportedVersion, ...json});
    final bytes = utf8.encode('$text\n');
    _checkSize(bytes);
    return bytes;
  }

  /// Reads one project without making changes to the workspace.
  ///
  /// Throws [UnsupportedProjectFileVersion] for another version and
  /// [FormatException] for malformed or invalid data.
  static ProjectSnapshot decode(Uint8List bytes) {
    _checkSize(bytes);
    final json = decodeJsonObject(utf8.decode(bytes));
    final version = json.remove('schemaVersion');
    if (version is! int) {
      throw const FormatException('Invalid project file version.');
    }
    if (version != supportedVersion) {
      throw UnsupportedProjectFileVersion(version);
    }
    return _parseProject(json);
  }

  static void _checkSize(Uint8List bytes) {
    if (bytes.length > BehaviorPolicy.maxProjectFileBytes) {
      throw const FormatException('Project file is too large.');
    }
  }

  static ProjectSnapshot _parseProject(Map<String, Object?> json) {
    final project = ProjectSnapshot.fromJson(json);
    final form = project.formModel;
    final options = SampleSizeCatalog.optionsFor(
      factorCount: form.experimentStructure.factorCount,
      riskLevel: form.riskLevel,
    );
    if (!options.contains(form.sampleSizeOption) ||
        form.projectTitle.runes.length > BehaviorPolicy.maxProjectTitleLength ||
        form.factorDefinitions.length != _factorSlots ||
        project.matrixState.length > _maxMatrixEntries) {
      throw const FormatException('Invalid project file data.');
    }
    for (final factor in form.factorDefinitions) {
      if ([
        factor.name,
        factor.firstState,
        factor.secondState,
      ].any((label) => label.runes.length > _maxFactorLabelLength)) {
        throw const FormatException('Invalid factor label.');
      }
    }
    for (final entry in project.matrixState.entries) {
      final index = int.tryParse(
        _rangeKey.firstMatch(entry.key)?.group(1) ?? '',
      );
      if (index == null ||
          index >= _maxMatrixEntries ||
          RangeValueParser.parse(entry.value).invalid) {
        throw const FormatException('Invalid matrix measurement.');
      }
    }
    final sequence = project.randomizeSequence;
    if (sequence != null &&
        (sequence.length > _maxMatrixEntries ||
            sequence.toSet().length != sequence.length ||
            sequence.any((index) => index >= _maxMatrixEntries))) {
      throw const FormatException('Invalid randomized order.');
    }

    // The storage reader accepts legacy omissions and enum fallbacks. File
    // imports require the exact current shape and must not silently default.
    final canonical = project.toJson()
      ..['createdAt'] = json['createdAt']
      ..['updatedAt'] = json['updatedAt'];
    if (!_sameJson(canonical, json)) {
      throw const FormatException('Invalid project file structure.');
    }
    return project;
  }

  static bool _sameJson(Object? expected, Object? actual) {
    if (expected is Map<String, Object?>) {
      return actual is Map<String, Object?> &&
          actual.length == expected.length &&
          expected.entries.every(
            (entry) =>
                actual.containsKey(entry.key) &&
                _sameJson(entry.value, actual[entry.key]),
          );
    }
    if (expected is List<Object?>) {
      if (actual is! List<Object?> || actual.length != expected.length) {
        return false;
      }
      for (var index = 0; index < expected.length; index++) {
        if (!_sameJson(expected[index], actual[index])) {
          return false;
        }
      }
      return true;
    }
    return expected == actual;
  }
}
