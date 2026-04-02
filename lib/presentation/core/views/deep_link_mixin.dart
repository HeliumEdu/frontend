// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/core/views/notification_screen.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';

/// Mixin for shell screens that handle deep link query parameters.
///
/// Provides shared infrastructure for:
/// - `openedDeepLinkParam` rebuild guard
/// - Global entity params (`homeworkId`/`eventId`) → planner item editor
/// - Dialog params (`dialog=settings|notifications`)
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
  /// Uses [router.routerDelegate] directly rather than [GoRouterState.of]
  /// because [GoRouterState] is an [InheritedWidget] that updates on the next
  /// build — it lags by one frame when [_onRouteChanged] fires immediately
  /// after a [router.go] or [router.replace] call.
  @protected
  Map<String, String> readQueryParams() =>
      router.routerDelegate.currentConfiguration.uri.queryParameters;

  /// Override to handle route-specific entity params (e.g., `id` on /classes).
  /// Return true if a param was consumed (skips dialog param handling).
  @protected
  bool handleRouteEntityParams(Map<String, String> queryParams) => false;

  @override
  void initState() {
    super.initState();
    router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  /// Opens deep-linked content based on current query params.
  /// Priority: global entity params → route-specific → dialog params.
  @protected
  void openFromQueryParams() {
    final queryParams = readQueryParams();
    if (_handleGlobalEntityParams(queryParams)) return;
    if (handleRouteEntityParams(queryParams)) return;
    _handleDialogParams(queryParams);
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

  /// Sets the guard and opens content immediately (for in-app taps).
  /// Skips if a dialog is already open (guard already set).
  @protected
  void openWithGuard(String paramKey, Future<void> Function() open) {
    if (openedDeepLinkParam != null) return;
    openedDeepLinkParam = paramKey;
    open().then((_) => openedDeepLinkParam = null);
  }

  void _onRouteChanged() {
    if (!mounted) return;
    // Skip if a dialog is already open, URL changes are from the dialog
    // itself, not from an external source.
    if (openedDeepLinkParam != null) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.path != routePath) return;
    if (uri.queryParameters.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      openFromQueryParams();
    });
  }

  bool _handleGlobalEntityParams(Map<String, String> queryParams) {
    final homeworkIdParam = queryParams[DeepLinkParam.homeworkId];
    final eventIdParam = queryParams[DeepLinkParam.eventId];

    if (homeworkIdParam == null && eventIdParam == null) return false;

    final rawParam = homeworkIdParam ?? eventIdParam!;
    final parsed = DeepLinkParam.parseId(rawParam);

    final tabValue =
        int.tryParse(queryParams[DeepLinkParam.tab] ?? '') ?? 1;
    final initialStep = (tabValue - 1).clamp(0, 2);

    final paramKey = homeworkIdParam != null
        ? '${DeepLinkParam.homeworkId}:$homeworkIdParam'
        : '${DeepLinkParam.eventId}:$eventIdParam';

    return openFromDeepLink(
      paramKey,
      () => _validateAndOpenPlannerItem(
        homeworkId: homeworkIdParam != null ? parsed.id : null,
        eventId: eventIdParam != null ? parsed.id : null,
        isNew: parsed.isNew,
        initialStep: initialStep,
      ),
    );
  }

  Future<void> _validateAndOpenPlannerItem({
    int? homeworkId,
    int? eventId,
    required bool isNew,
    required int initialStep,
  }) async {
    // For new items, skip validation
    if (!isNew) {
      try {
        final dioClient = DioClient();
        if (homeworkId != null) {
          await HomeworkRemoteDataSourceImpl(dioClient: dioClient)
              .getHomework(id: homeworkId);
        } else if (eventId != null) {
          await EventRemoteDataSourceImpl(dioClient: dioClient)
              .getEvent(id: eventId);
        }
      } catch (_) {
        // Entity doesn't exist, skip silently
        return;
      }
    }

    if (!mounted) return;

    await showPlannerItemAdd(
      context,
      homeworkId: homeworkId,
      eventId: eventId,
      isEdit: !isNew,
      isNew: isNew,
      initialStep: initialStep,
    );
  }

  void _handleDialogParams(Map<String, String> queryParams) {
    final dialogParam = queryParams[DeepLinkParam.dialog];
    if (dialogParam == null) return;

    final key = '${DeepLinkParam.dialog}:$dialogParam';
    if (openedDeepLinkParam == key) return;
    openedDeepLinkParam = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (dialogParam == DeepLinkParam.dialogSettings) {
        final tab = int.tryParse(queryParams[DeepLinkParam.tab] ?? '');
        showSettings(context, initialTab: tab).then(
          (_) => openedDeepLinkParam = null,
        );
      } else if (dialogParam == DeepLinkParam.dialogNotifications) {
        showNotifications(context).then(
          (_) => openedDeepLinkParam = null,
        );
      }
    });
  }
}
