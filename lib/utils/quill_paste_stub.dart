// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

/// No-op stub used on non-web platforms.
/// On native (iOS/Android), the platform handles clipboard natively — no
/// browser event interception needed.
void Function()? registerQuillClipboardListeners({
  required bool Function() isEditorFocused,
  required ({String html, String plain})? Function() onCopy,
  required void Function(String? html, String? plainText) onPaste,
}) =>
    null;
