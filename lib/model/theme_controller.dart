// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../styles/app_design.dart';

/// Owns the user's light/dark theme preference and persists it across launches.
///
/// Exposed to the widget tree via `provider` so the root [MaterialApp] can
/// react to changes (rebuilding with the new `themeMode`) and so any control
/// — e.g. the home page dark-mode toggle — can read and update the choice.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode? initialMode})
    : _themeMode = initialMode ?? AppDesign.defaultThemeMode;

  /// SharedPreferences key under which the chosen [ThemeMode] name is stored.
  static const String _storageKey = 'anomr_theme_mode_v1';

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
  /// available (e.g. widget tests): failures simply leave the default in place.
  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      final restored = _themeModeFromName(stored);
      if (restored != null && restored != _themeMode) {
        _themeMode = restored;
        notifyListeners();
      }
    } catch (_) {
      // No persistent store available; keep the in-memory default.
    }
  }

  /// Updates and persists the selected [mode].
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, mode.name);
    } catch (_) {
      // Persistence is best-effort; the in-memory value still applies.
    }
  }

  /// Convenience for a binary toggle: dark when [enabled], light otherwise.
  Future<void> setDarkMode({required bool enabled}) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  static ThemeMode? _themeModeFromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}
