// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _log = Logger('analytics');

/// A no-op navigator observer for use when analytics is disabled.
class _NoOpNavigatorObserver extends NavigatorObserver {}

class AnalyticsService {
  FirebaseAnalytics? _analytics;

  /// Whether analytics is enabled. Configured via ANALYTICS_ENABLED env var.
  /// Defaults to true. Set to 'false' to disable analytics collection.
  static const _analyticsEnabled =
      String.fromEnvironment('ANALYTICS_ENABLED', defaultValue: 'true');

  bool get isEnabled => _analyticsEnabled.toLowerCase() == 'true';

  bool _isInitialized = false;

  static AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  @visibleForTesting
  AnalyticsService.forTesting({required FirebaseAnalytics analytics})
      : _analytics = analytics;

  @visibleForTesting
  static void resetForTesting() {
    _instance = AnalyticsService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(AnalyticsService instance) {
    _instance = instance;
  }

  FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  NavigatorObserver get observer {
    if (!isEnabled) {
      return _NoOpNavigatorObserver();
    }
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  Future<void> init() async {
    if (_isInitialized || !isEnabled) return;

    try {
      await analytics.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;
      _log.info('Analytics initialized successfully');
    } catch (e, s) {
      _log.severe('Analytics initialization failed', e, s);
      rethrow;
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    if (!isEnabled) return;
    try {
      await analytics.logScreenView(screenName: screenName);
    } catch (e) {
      _log.warning('Failed to log screen view: $screenName', e);
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!isEnabled) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      _log.warning('Failed to log event: $name', e);
    }
  }

  Future<void> logLogin({String? loginMethod}) async {
    if (!isEnabled) return;
    try {
      await analytics.logLogin(loginMethod: loginMethod);
    } catch (e) {
      _log.warning('Failed to log login event', e);
    }
  }

  Future<void> logSignUp({String signUpMethod = 'email'}) async {
    if (!isEnabled) return;
    try {
      await analytics.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      _log.warning('Failed to log sign up event', e);
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;
    try {
      await analytics.setUserId(id: userId);
    } catch (e) {
      _log.warning('Failed to set user ID', e);
    }
  }

  bool get isInitialized => _isInitialized;
}
