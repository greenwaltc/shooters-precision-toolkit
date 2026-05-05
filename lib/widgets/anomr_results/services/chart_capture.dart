import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Helper that turns a [RepaintBoundary] keyed widget into PNG bytes.
class ChartCapture {
  const ChartCapture._();

  /// Renders the [RepaintBoundary] referenced by [key] to a PNG.
  ///
  /// Returns `null` if the key isn't currently attached or doesn't reference
  /// a [RenderRepaintBoundary].
  static Future<Uint8List?> capture(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }
}
