import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bramwells_precision_test_kit/styles/layout/app_viewport.dart';

void main() {
  group('AppViewport.clampTextScaler', () {
    test('passes through values inside the supported range', () {
      const scaler = TextScaler.linear(1.3);
      final clamped = AppViewport.clampTextScaler(scaler);

      expect(clamped.scale(10), scaler.scale(10));
    });

    test('caps magnification at the maximum factor', () {
      final clamped = AppViewport.clampTextScaler(
        const TextScaler.linear(3.0),
      );

      expect(
        clamped.scale(10),
        const TextScaler.linear(AppViewport.maxTextScaleFactor).scale(10),
      );
    });

    test('raises tiny scales up to the minimum factor', () {
      final clamped = AppViewport.clampTextScaler(
        const TextScaler.linear(0.3),
      );

      expect(
        clamped.scale(10),
        const TextScaler.linear(AppViewport.minTextScaleFactor).scale(10),
      );
    });
  });
}
