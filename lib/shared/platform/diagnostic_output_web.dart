import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Writes a sanitized JSON event to the browser console.
void writeStructuredDiagnostic(String json) => web.console.log(json.toJS);
