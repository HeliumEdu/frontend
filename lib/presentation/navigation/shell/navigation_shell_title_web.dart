// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:web/web.dart' as web;

/// Sets the browser tab title directly via DOM.
/// This is used by NavigationShell to avoid Title widget conflicts
/// with pushed routes like Settings/Notifications.
void setTitle(String title) {
  web.document.title = title;
}
