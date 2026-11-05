import 'package:flutter/foundation.dart' show debugPrintSynchronously;

// Flutter routes this to the platform log in both debug and release builds.
void writeStructuredDiagnostic(String json) => debugPrintSynchronously(json);
