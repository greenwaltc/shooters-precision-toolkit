// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../foundation/app_failure.dart';
import '../../foundation/theme_preference_storage.dart';
import 'app_design.dart';

/// Owns the user's light/dark theme preference and persists it across launches.
///
/// Exposed to the widget tree via `provider` so the root [MaterialApp] can
/// react to changes (rebuilding with the new `themeMode`) and so any control
/// — e.g. the home page dark-mode toggle — can read and update the choice.
/// Pending reads are ignored after a newer selection or disposal. Writes
/// requested before disposal finish in order; later requests are no-ops.
class ThemeController extends ChangeNotifier {
  /// Creates a theme controller backed by [storage].
  ///
  /// Omit [initialMode] to follow the system until a saved preference is
  /// loaded.
  ThemeController({ThemeMode? initialMode, required this.storage})
    : _themeMode = initialMode ?? AppDesign.defaultThemeMode;

  final ThemePreferenceStorage storage;
  Future<void> _writeTail = Future.value();
  int _generation = 0;
  bool _disposed = false;

  ThemeMode _themeMode;

  /// Currently selected theme mode (`system`, `light`, or `dark`).
  ThemeMode get themeMode => _themeMode;

  /// Resolves whether dark is *effectively* active for [context], accounting
  /// for `ThemeMode.system` by reading the platform brightness.
  bool isDarkActive(BuildContext context) {
    return switch (_themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  /// Loads the persisted preference. Safe to call when no platform storage is
  /// available (e.g. widget tests): expected storage exceptions leave the
  /// default in place. Unexpected programming errors propagate to the caller.
  Future<void> load() async {
    if (_disposed) {
      return;
    }
    final generation = ++_generation;
    try {
      final stored = await storage.read();
      if (_disposed || generation != _generation) {
        return;
      }
      final restored = _themeModeFromName(stored);
      if (restored != null && restored != _themeMode) {
        _themeMode = restored;
        notifyListeners();
      }
    } on AppFailure {
      // No persistent store available; keep the in-memory default.
    }
  }

  /// Updates and persists the selected [mode].
  Future<void> setThemeMode(ThemeMode mode) {
    if (_disposed || _themeMode == mode) {
      return Future.value();
    }
    _generation++;
    _themeMode = mode;
    notifyListeners();

    // Preserve user-action order even if platform storage completes out of order.
    // Disposal stops notifications, but lets already requested writes complete.
    final write = _writeTail.then((_) => _persistMode(mode));
    _writeTail = write;
    return write;
  }

  Future<void> _persistMode(ThemeMode mode) async {
    try {
      await storage.write(mode.name);
    } on AppFailure {
      // Persistence is best-effort; the in-memory value still applies.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  /// Convenience for a binary toggle: dark when [enabled], light otherwise.
  Future<void> setDarkMode({required bool enabled}) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  static ThemeMode? _themeModeFromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return null;
  }
}
