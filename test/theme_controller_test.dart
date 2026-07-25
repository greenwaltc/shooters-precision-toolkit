import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bramwells_precision_test_kit/model/theme_controller.dart';
import 'package:bramwells_precision_test_kit/styles/app_theme.dart';
import 'package:bramwells_precision_test_kit/styles/theme_extensions/pluto_grid_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController', () {
    test('defaults to system mode', () {
      expect(ThemeController().themeMode, ThemeMode.system);
    });

    test('setDarkMode flips between dark and light', () async {
      final controller = ThemeController();

      await controller.setDarkMode(enabled: true);
      expect(controller.themeMode, ThemeMode.dark);

      await controller.setDarkMode(enabled: false);
      expect(controller.themeMode, ThemeMode.light);
    });

    test('notifies listeners only on a real change', () async {
      final controller = ThemeController(initialMode: ThemeMode.light);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setThemeMode(ThemeMode.light);
      expect(notifications, 0);

      await controller.setThemeMode(ThemeMode.dark);
      expect(notifications, 1);
    });

    test('persists and restores the chosen mode', () async {
      SharedPreferences.setMockInitialValues({});

      final controller = ThemeController();
      await controller.setThemeMode(ThemeMode.dark);

      final restored = ThemeController();
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
