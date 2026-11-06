import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../shared/ui/navigation/app_routes.dart';
import 'editor_resume.dart';

/// Scopes the project location to the current tab and Firebase account.
EditorResume editorResumeForAccount(String namespace, String uid) =>
    _BrowserEditorResume('precision/editor/$namespace/$uid');

class _BrowserEditorResume implements EditorResume {
  _BrowserEditorResume(this._key);

  final String _key;

  @override
  EditorLocation? takeReloadLocation() {
    try {
      final storage = web.window.sessionStorage;
      final saved = storage.getItem(_key);
      storage.removeItem(_key);
      final navigation = web.window.performance.getEntriesByType('navigation');
      if (saved == null ||
          navigation.toDart.isEmpty ||
          (navigation.toDart.first as web.PerformanceNavigationTiming).type !=
              'reload') {
        return null;
      }
      final decoded = jsonDecode(saved);
      return switch (decoded) {
        [final String id, final String route]
            when id.isNotEmpty &&
                !id.contains('/') &&
                (route == AppRoutes.projects ||
                    route == AppRoutes.projectForm ||
                    route == AppRoutes.anomrMatrix) =>
          (projectId: id, route: route),
        _ => null,
      };
    } catch (_) {
      // Browser storage can be blocked and the previous record may be invalid.
      return null;
    }
  }

  @override
  void remember(EditorLocation? location) {
    try {
      final storage = web.window.sessionStorage;
      if (location == null) {
        storage.removeItem(_key);
      } else {
        storage.setItem(_key, jsonEncode([location.projectId, location.route]));
      }
    } catch (_) {
      // Editing still works when browser storage is blocked.
    }
  }
}
