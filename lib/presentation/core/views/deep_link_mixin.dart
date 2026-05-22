// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';

/// Mixin for shell screens that handle deep link query parameters.
///
/// Provides shared infrastructure for:
/// - `openedDeepLinkParam` rebuild guard
/// - Route-specific entity params via [handleRouteEntityParams] override
/// - Router listener for entity params set externally (e.g., from notifications)
///
/// Call [openFromQueryParams] from the screen's data-loaded callback.
mixin DeepLinkMixin<T extends StatefulWidget> on BasePageScreenState<T> {
  @protected
  String? openedDeepLinkParam;

  /// The route path this screen is registered at (e.g., `/planner`).
  /// Used by the router listener to filter URL changes to this screen only.
  @protected
  String get routePath;

  /// Reads query params from the current route.
  ///
  /// Uses [router.routeInformationProvider] rather than [router.routerDelegate]
  /// because [routeInformationProvider] fires (and updates) for same-shell-path
  /// URL changes (e.g., `/planner` --> `/planner?id=42`) that
  /// [routerDelegate] may skip when the navigator stack doesn't change.
  /// Reading from the same source we listen to keeps the check and the read
  /// in sync, preventing stale-param feedback loops on dialog close.
  @protected
  Map<String, String> readQueryParams() =>
      router.routeInformationProvider.value.uri.queryParameters;

  /// Override to handle route-specific entity params (e.g., `id` on /classes).
  /// Return true if a param was consumed.
  @protected
  bool handleRouteEntityParams(Map<String, String> queryParams) => false;

  @override
  void initState() {
    super.initState();
    router.routeInformationProvider.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    router.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  /// Opens deep-linked content based on current query params.
  @protected
  void openFromQueryParams() {
    final queryParams = readQueryParams();
    handleRouteEntityParams(queryParams);
  }

  /// Sets the guard and opens content via [addPostFrameCallback].
  /// Returns false (skips) if the guard already matches [paramKey].
  @protected
  bool openFromDeepLink(String paramKey, Future<void> Function() open) {
    if (openedDeepLinkParam == paramKey) return false;
    openedDeepLinkParam = paramKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      open().then((_) => openedDeepLinkParam = null);
    });
    return true;
  }

  void _onRouteChanged() {
    if (!mounted) return;
    // Skip if a dialog is already open, URL changes are from the dialog
    // itself, not from an external source.
    if (openedDeepLinkParam != null) return;
    final uri = router.routeInformationProvider.value.uri;
    if (uri.path != routePath) return;
    if (uri.queryParameters.isEmpty) return;
    // Defer until after GoRouter's route-change notification completes so
    // the new route is fully committed before we attempt to open content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      openFromQueryParams();
    });
  }
}
