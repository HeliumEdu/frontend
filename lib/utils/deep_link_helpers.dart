// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_router.dart';

/// URL synchronization helpers for deep link support.
///
/// These extensions keep the browser/app URL in sync with open dialogs and
/// sub-screens. The pattern is:
///
/// 1. Call [setQueryParam] before opening a dialog to write the deep link URL.
/// 2. Chain `.then((_) => clearRouteQueryParams(basePath))` on [showScreenAsDialog]
///    to clear it when the dialog closes.
/// 3. On a direct URL visit the screen reads the same params after data loads
///    and opens accordingly (existing pattern, unchanged).
extension DeepLinkContext on BuildContext {
  /// Adds or replaces [key]=[value] in the current URL without pushing a new
  /// history entry. All other query parameters are preserved.
  void setQueryParam(String key, String value) {
    final currentUri = router.routerDelegate.currentConfiguration.uri;
    router.replace(
      currentUri
          .replace(
            queryParameters: {...currentUri.queryParameters, key: value},
          )
          .toString(),
    );
  }

  /// Atomically removes [removeKey] and sets [key]=[value] in a single
  /// URL update. Use when swapping one param for another (e.g., toggling
  /// between `homeworkId` and `eventId`).
  void replaceQueryParam(String removeKey, String key, String value) {
    final currentUri = router.routerDelegate.currentConfiguration.uri;
    final params = Map<String, String>.from(currentUri.queryParameters)
      ..remove(removeKey)
      ..[key] = value;
    router.replace(
      currentUri.replace(queryParameters: params).toString(),
    );
  }

  /// Removes [key] from the current URL without pushing a new history entry.
  /// All other query parameters are preserved.
  void clearQueryParam(String key) {
    final currentUri = router.routerDelegate.currentConfiguration.uri;
    final params = Map<String, String>.from(currentUri.queryParameters)
      ..remove(key);
    router.replace(
      params.isEmpty
          ? currentUri.path
          : currentUri.replace(queryParameters: params).toString(),
    );
  }
}

/// Strips all query parameters from the current URL without pushing a new
/// history entry. Use this in dialog close callbacks to restore the base URL:
///
/// ```dart
/// final basePath = router.routerDelegate.currentConfiguration.uri.path;
/// showScreenAsDialog(context, child: ...).then((_) => clearRouteQueryParams(basePath));
/// ```
///
/// [expectedPath] is the route path that was active when the dialog opened.
/// If the user navigated away before the dialog closed (e.g., "Open in
/// Notebook" triggers `context.go()` to a new route), clearing is skipped
/// so the new route's query params are not wiped.
///
/// This is a free function (not an extension) so it can be called safely from
/// `.then()` callbacks where the original [BuildContext] may no longer be
/// mounted.
///
/// Note: uses [currentUri.path] directly rather than
/// `currentUri.replace(queryParameters: null)` — in Dart, passing null for
/// queryParameters preserves the existing params rather than clearing them.
void clearRouteQueryParams(String expectedPath) {
  final currentUri = router.routerDelegate.currentConfiguration.uri;
  if (currentUri.path != expectedPath) return;
  if (currentUri.queryParameters.isEmpty) return;
  router.replace(currentUri.path);
}

/// Navigates to [uri] via GoRouter and clears all Navigator-pushed routes.
///
/// Use when a sub-page needs to redirect to a different shell route (e.g.,
/// "Open in Notebook" from a planner item). Without this, Navigator-pushed
/// screens (notifications, entity editors) remain on the stack and the close
/// button walks back through them instead of closing to the target route.
///
/// The route change fires first so that any `.then()` cleanup callbacks
/// (e.g., `clearRouteQueryParams`) see the new path and skip clearing.
void navigateAndClearStack(BuildContext context, String uri) {
  router.go(uri);
  Navigator.of(context).popUntil((route) => route.isFirst);
}
