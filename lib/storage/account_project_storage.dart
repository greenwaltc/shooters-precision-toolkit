import 'package:shared_preferences/shared_preferences.dart';

import 'project_storage.dart';

class AccountProjectStorage implements ProjectStorage {
  AccountProjectStorage({required String projectId, required String uid})
    : _key =
          'account_projects_v1/'
          '${Uri.encodeComponent(projectId)}/'
          '${Uri.encodeComponent(uid)}';

  final String _key;

  @override
  Future<String?> readProjectsJson() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  @override
  Future<void> writeProjectsJson(String projectsJson) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_key, projectsJson);

    if (!saved) {
      throw StateError('Unable to save the workspace.');
    }
  }
}
