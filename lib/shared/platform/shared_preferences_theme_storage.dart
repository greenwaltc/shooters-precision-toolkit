import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../foundation/app_failure.dart';
import '../foundation/theme_preference_storage.dart';

/// Non-sensitive preference only; credentials and project content never use it.
final class SharedPreferencesThemeStorage implements ThemePreferenceStorage {
  /// Creates a theme preference adapter that obtains preferences through
  /// [preferencesLoader].
  const SharedPreferencesThemeStorage({required this.preferencesLoader});
  final Future<SharedPreferences> Function() preferencesLoader;
  static const key = 'anomr_theme_mode_v1';

  @override
  Future<String?> read() => _guard(() async {
    final value = (await preferencesLoader()).get(key);
    return value is String ? value : null;
  });
  @override
  Future<void> write(String name) => _guard(() async {
    if (!await (await preferencesLoader()).setString(key, name)) {
      throw const AppFailure(FailureKind.unavailable);
    }
  });
  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PlatformException catch (_, stack) {
      Error.throwWithStackTrace(
        const AppFailure(FailureKind.unavailable),
        stack,
      );
    } on MissingPluginException catch (_, stack) {
      Error.throwWithStackTrace(
        const AppFailure(FailureKind.unavailable),
        stack,
      );
    }
  }
}
