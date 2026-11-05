import 'package:flutter/foundation.dart' show debugPrintSynchronously;

// Flutter routes this to the platform log in both debug and release builds.
/// Writes a sanitized JSON event to the native Flutter log.
void writeStructuredDiagnostic(String json) => debugPrintSynchronously(json);
