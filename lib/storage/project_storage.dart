// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:shared_preferences/shared_preferences.dart';

abstract class ProjectStorage {
  Future<String?> readProjectsJson();
  Future<void> writeProjectsJson(String projectsJson);
}

class SharedPreferencesProjectStorage implements ProjectStorage {
  static const _projectsKey = 'anomr_projects_v1';

  @override
  Future<String?> readProjectsJson() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_projectsKey);
  }

  @override
  Future<void> writeProjectsJson(String projectsJson) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_projectsKey, projectsJson);
  }
}

class InMemoryProjectStorage implements ProjectStorage {
  String? _projectsJson;

  @override
  Future<String?> readProjectsJson() async => _projectsJson;

  @override
  Future<void> writeProjectsJson(String projectsJson) async {
    _projectsJson = projectsJson;
  }
}
