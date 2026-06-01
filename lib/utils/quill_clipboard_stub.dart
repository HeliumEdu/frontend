// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// No-op stub used on non-web platforms.
/// On native (iOS/Android), Quill's enableExternalRichPaste handles HTML via
/// quill_native_bridge natively — no web clipboard API needed.
Future<String?> readHtmlFromClipboard() async => null;
