// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:shared_preferences/shared_preferences.dart';

/// Persistence boundary for serialized project state.
abstract class ProjectStorage {
  /// Reads the serialized project payload, or `null` when nothing is saved.
  Future<String?> readProjectsJson();

  /// Persists the serialized project payload.
  Future<void> writeProjectsJson(String projectsJson);
}

/// [ProjectStorage] backed by Flutter's shared preferences store.
class SharedPreferencesProjectStorage implements ProjectStorage {
  static const _projectsKey = 'anomr_projects_v1';

  /// Reads the project payload from shared preferences.
  @override
  Future<String?> readProjectsJson() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_projectsKey);
  }

  /// Writes the project payload to shared preferences.
  @override
  Future<void> writeProjectsJson(String projectsJson) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_projectsKey, projectsJson);
  }
}

/// In-memory storage for widget tests and short-lived previews.
class InMemoryProjectStorage implements ProjectStorage {
  String? _projectsJson;

  /// Returns the last payload written to memory.
  @override
  Future<String?> readProjectsJson() async => _projectsJson;

  /// Stores [projectsJson] for the lifetime of this object.
  @override
  Future<void> writeProjectsJson(String projectsJson) async {
    _projectsJson = projectsJson;
  }
}
