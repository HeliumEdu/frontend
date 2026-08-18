// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:web/web.dart' as web;

/// Sets the browser tab title directly via DOM.
/// This is used by NavigationShell to avoid Title widget conflicts
/// with pushed routes like Settings/Notifications.
void setTitle(String title) {
  web.document.title = title;
}
