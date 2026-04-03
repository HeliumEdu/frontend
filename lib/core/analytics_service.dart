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

/// A no-op navigator observer for use when analytics is disabled
class _NoOpNavigatorObserver extends NavigatorObserver {}

class AnalyticsService {
  FirebaseAnalytics? _analytics;

  bool _isStaff = false;

  bool get isEnabled => !kDebugMode && !_isStaff;

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

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!isEnabled) return;
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      _log.warning('Failed to set user property: $name', e);
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> setStaffStatus(String email) async {
    final lowerEmail = email.toLowerCase();
    if (lowerEmail.endsWith('@heliumedu.com') ||
        lowerEmail.endsWith('@heliumedu.dev')) {
      _isStaff = true;
      try {
        await analytics.setAnalyticsCollectionEnabled(false);
        _log.info('Analytics disabled for staff user');
      } catch (e) {
        _log.warning('Failed to disable analytics collection', e);
      }
    }
  }
}
