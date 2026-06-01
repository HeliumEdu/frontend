// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:js_interop';

import 'package:web/web.dart';

/// Reads HTML from the system clipboard via the Async Clipboard API.
///
/// Returns null if the clipboard contains no HTML, the API is unavailable,
/// or the user denies the clipboard-read permission.
Future<String?> readHtmlFromClipboard() async {
  try {
    final items = (await window.navigator.clipboard.read().toDart).toDart;
    for (final item in items) {
      if (item.types.toDart.contains('text/html'.toJS)) {
        final blob = await item.getType('text/html').toDart;
        return (await blob.text().toDart).toDart;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}
