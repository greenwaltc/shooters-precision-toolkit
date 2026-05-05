import 'package:flutter/material.dart';

/// Six-stop palette used to color the per-factor line segments and their
/// matching legend / conclusion indicators.
class FactorPalette {
  const FactorPalette._();

  static const List<Color> colors = <Color>[
    Color(0xFF2E7DD1), // azure
    Color(0xFFE07B2E), // amber-orange
    Color(0xFF2EA87B), // jade green
    Color(0xFF8B4FBF), // violet
    Color(0xFFC62957), // berry
    Color(0xFF3F6E8C), // slate blue
  ];

  static Color colorFor(int index) => colors[index % colors.length];
}
