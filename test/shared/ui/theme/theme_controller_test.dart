import 'dart:async';

import 'package:bramwells_precision_test_kit/shared/platform/shared_preferences_theme_storage.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/app_theme.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/theme_controller.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/theme_extensions/pluto_grid_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController', () {
    test('late preference loads cannot notify a disposed controller', () async {
      SharedPreferences.setMockInitialValues({'anomr_theme_mode_v1': 'dark'});
      final preferences = await SharedPreferences.getInstance();
      final pending = Completer<SharedPreferences>();
      final controller = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: () => pending.future,
        ),
      );
      final load = controller.load();
      controller.dispose();
      pending.complete(preferences);
      await load;
      expect(controller.themeMode, ThemeMode.system);
    });

    test('a user theme change wins over an older pending load', () async {
      SharedPreferences.setMockInitialValues({'anomr_theme_mode_v1': 'dark'});
      final preferences = await SharedPreferences.getInstance();
      final pending = Completer<SharedPreferences>();
      final controller = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: () => pending.future,
        ),
      );
      final load = controller.load();
      final write = controller.setThemeMode(ThemeMode.light);
      pending.complete(preferences);
      await Future.wait([load, write]);
      expect(controller.themeMode, ThemeMode.light);
      expect(preferences.getString('anomr_theme_mode_v1'), 'light');
      controller.dispose();
    });

    test('rapid theme changes persist in request order', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = Completer<SharedPreferences>();
      var calls = 0;
      final controller = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: () =>
              ++calls == 1 ? first.future : Future.value(preferences),
        ),
      );
      final dark = controller.setThemeMode(ThemeMode.dark);
      final light = controller.setThemeMode(ThemeMode.light);
      await Future<void>.value();
      expect(calls, 1);
      first.complete(preferences);
      await Future.wait([dark, light]);
      expect(preferences.getString('anomr_theme_mode_v1'), 'light');
      controller.dispose();
    });

    test('defaults to system mode', () {
      expect(
        ThemeController(
          storage: SharedPreferencesThemeStorage(
            preferencesLoader: SharedPreferences.getInstance,
          ),
        ).themeMode,
        ThemeMode.system,
      );
    });

    test('setDarkMode flips between dark and light', () async {
      final controller = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: SharedPreferences.getInstance,
        ),
      );

      await controller.setDarkMode(enabled: true);
      expect(controller.themeMode, ThemeMode.dark);

      await controller.setDarkMode(enabled: false);
      expect(controller.themeMode, ThemeMode.light);
    });

    test('notifies listeners only on a real change', () async {
      final controller = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: SharedPreferences.getInstance,
        ),
        initialMode: ThemeMode.light,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setThemeMode(ThemeMode.light);
      expect(notifications, 0);

      await controller.setThemeMode(ThemeMode.dark);
      expect(notifications, 1);
    });

    test('persists and restores the chosen mode', () async {
      SharedPreferences.setMockInitialValues({});

      final controller = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: SharedPreferences.getInstance,
        ),
      );
      await controller.setThemeMode(ThemeMode.dark);

      final restored = ThemeController(
        storage: SharedPreferencesThemeStorage(
          preferencesLoader: SharedPreferences.getInstance,
        ),
      );
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
    });
  });

  group('AppTheme', () {
    test('PlutoGridStyleTheme follows light and dark color schemes', () {
      final light = AppTheme.light().extension<PlutoGridStyleTheme>()!;
      final dark = AppTheme.dark().extension<PlutoGridStyleTheme>()!;

      expect(light.backgroundColor, isNot(dark.backgroundColor));
      expect(light.factorCellBackground, isNot(dark.factorCellBackground));
      expect(light.borderColor, isNot(dark.borderColor));
    });
  });
}
