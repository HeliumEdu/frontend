// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_router.dart';

/// URL synchronization helpers for deep link support.
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

/// Clears all query params from the URL if still on [expectedPath].
///
/// Skips if the user navigated away (e.g., "Open in Notebook") so the new
/// route's params aren't wiped. Free function so it's safe in `.then()`.
void clearRouteQueryParams(String expectedPath) {
  final currentUri = router.routerDelegate.currentConfiguration.uri;
  if (currentUri.path != expectedPath) return;
  if (currentUri.queryParameters.isEmpty) return;
  router.replace(currentUri.path);
}

/// Navigates to [uri] and clears all Navigator-pushed routes from the stack.
void navigateAndClearStack(BuildContext context, String uri) {
  router.go(uri);
  Navigator.of(context).popUntil((route) => route.isFirst);
}
