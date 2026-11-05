import 'package:bramwells_precision_test_kit/shared/ui/theme/layout/app_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppViewport.clampTextScaler', () {
    test('passes through values inside the supported range', () {
      const scaler = TextScaler.linear(1.3);
      final clamped = AppViewport.clampTextScaler(scaler);

      expect(clamped.scale(10), scaler.scale(10));
    });

    test('honors the largest accessibility magnification', () {
      final clamped = AppViewport.clampTextScaler(const TextScaler.linear(3.0));

      expect(clamped.scale(10), 30);
    });

    test('raises tiny scales up to the minimum factor', () {
      final clamped = AppViewport.clampTextScaler(const TextScaler.linear(0.3));

      expect(
        clamped.scale(10),
        const TextScaler.linear(AppViewport.minTextScaleFactor).scale(10),
      );
    });
  });
}
