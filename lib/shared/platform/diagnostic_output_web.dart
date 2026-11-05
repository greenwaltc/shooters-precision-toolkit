import 'dart:js_interop';

import 'package:web/web.dart' as web;

void writeStructuredDiagnostic(String json) => web.console.log(json.toJS);
