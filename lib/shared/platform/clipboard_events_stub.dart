import '../foundation/clipboard_events.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.

final class BrowserClipboardEvents implements ClipboardEvents {
  const BrowserClipboardEvents();
  @override
  void Function() register({
    required bool Function() acceptsPaste,
    required String? Function() copyText,
    required void Function(String) pasteText,
  }) => () {};
}
