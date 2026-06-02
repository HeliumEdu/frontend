// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:js_interop';

import 'package:web/web.dart';

/// Registers document-level `copy` and `paste` event listeners for the Quill
/// editor on web.
///
/// **Copy**: [onCopy] is called synchronously when the user copies with the
/// editor focused. It must return `({String html, String plain})` with the
/// content to place on the clipboard, or `null` for a collapsed/empty
/// selection. The listener calls [ClipboardEvent.preventDefault] and writes
/// both representations via [ClipboardEvent.clipboardData.setData] — no
/// clipboard-write permission required.
///
/// **Paste**: [onPaste] is called with the raw clipboard HTML and plain text
/// read from [ClipboardEvent.clipboardData] (no clipboard-read permission
/// required). Both listeners run in capture phase so they fire before
/// Flutter's textarea handlers.
///
/// Returns a single callback that removes both listeners; call it in dispose.
void Function()? registerQuillClipboardListeners({
  required bool Function() isEditorFocused,
  required ({String html, String plain})? Function() onCopy,
  required void Function(String? html, String? plainText) onPaste,
}) {
  final copyListener = (JSAny? event) {
    if (!isEditorFocused()) return;
    final content = onCopy();
    if (content == null) return;
    final clipEvent = event as ClipboardEvent;
    clipEvent.preventDefault();
    clipEvent.clipboardData?.setData('text/html', content.html);
    clipEvent.clipboardData?.setData('text/plain', content.plain);
  }.toJS;

  final pasteListener = (JSAny? event) {
    if (!isEditorFocused()) return;
    final clipEvent = event as ClipboardEvent;
    clipEvent.stopPropagation();
    clipEvent.preventDefault();
    final htmlRaw = clipEvent.clipboardData?.getData('text/html') ?? '';
    final plainRaw = clipEvent.clipboardData?.getData('text/plain') ?? '';
    onPaste(
      htmlRaw.isEmpty ? null : htmlRaw,
      plainRaw.isEmpty ? null : plainRaw,
    );
  }.toJS;

  document.addEventListener('copy', copyListener, true.toJS);
  document.addEventListener('paste', pasteListener, true.toJS);
  return () {
    document.removeEventListener('copy', copyListener, true.toJS);
    document.removeEventListener('paste', pasteListener, true.toJS);
  };
}
