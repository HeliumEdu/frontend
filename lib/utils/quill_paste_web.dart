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
/// editor focused. The implementation should capture the current Quill
/// selection Delta for use on subsequent same-tab pastes, since Flutter web
/// never calls [QuillController.clipboardSelection] via the browser copy path.
///
/// **Paste**: [onPaste] is called with the raw clipboard HTML and plain text
/// read from [ClipboardEvent.clipboardData] (no clipboard-read permission
/// required). Both listeners run in capture phase so they fire before
/// Flutter's textarea handlers.
///
/// Returns a single callback that removes both listeners; call it in dispose.
void Function()? registerQuillClipboardListeners({
  required bool Function() isEditorFocused,
  required void Function() onCopy,
  required void Function(String? html, String? plainText) onPaste,
}) {
  final copyListener = (JSAny? event) {
    if (!isEditorFocused()) return;
    onCopy();
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
