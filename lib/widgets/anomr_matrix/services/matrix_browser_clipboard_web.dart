// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.

import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Read only user-initiated clipboard events, while this matrix has focus.
/// Using paste-event data avoids stale internal copies and clipboard prompts.
void Function() registerMatrixBrowserClipboard({
  required bool Function() acceptsPaste,
  required String? Function() copyText,
  required void Function(String) pasteText,
}) {
  final paste = ((web.Event event) {
    if (!acceptsPaste()) {
      return;
    }
    final data = (event as web.ClipboardEvent).clipboardData;
    if (data == null) {
      return;
    }
    event.preventDefault();
    event.stopImmediatePropagation();
    pasteText(data.getData('text/plain'));
  }).toJS;
  final copy = ((web.Event event) {
    final text = copyText();
    if (text == null) {
      return;
    }
    final data = (event as web.ClipboardEvent).clipboardData;
    if (data == null) {
      return;
    }
    data.setData('text/plain', text);
    event.preventDefault();
    event.stopImmediatePropagation();
  }).toJS;
  for (final entry in {'paste': paste, 'copy': copy}.entries) {
    web.document.addEventListener(entry.key, entry.value, true.toJS);
  }
  return () {
    for (final entry in {'paste': paste, 'copy': copy}.entries) {
      web.document.removeEventListener(entry.key, entry.value, true.toJS);
    }
  };
}
