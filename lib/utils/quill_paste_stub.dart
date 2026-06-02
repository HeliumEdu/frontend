// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// No-op stub used on non-web platforms.
/// On native (iOS/Android), the platform handles clipboard natively — no
/// browser event interception needed.
void Function()? registerQuillClipboardListeners({
  required bool Function() isEditorFocused,
  required void Function() onCopy,
  required void Function(String? html, String? plainText) onPaste,
}) =>
    null;
