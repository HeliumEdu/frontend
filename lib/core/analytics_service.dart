// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _log = Logger('analytics');

class AnalyticsService {
  late final FirebaseAnalytics _analytics;

  bool _isInitialized = false;

  static AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal() : _analytics = FirebaseAnalytics.instance;

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

  FirebaseAnalytics get analytics => _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;
      _log.info('Analytics initialized successfully');
    } catch (e, s) {
      _log.severe('Analytics initialization failed', e, s);
      rethrow;
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      _log.warning('Failed to log screen view: $screenName', e);
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      _log.warning('Failed to log event: $name', e);
    }
  }

  Future<void> logLogin({String? loginMethod}) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
    } catch (e) {
      _log.warning('Failed to log login event', e);
    }
  }

  Future<void> logSignUp({String signUpMethod = 'email'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      _log.warning('Failed to log sign up event', e);
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      _log.warning('Failed to set user ID', e);
    }
  }

  bool get isInitialized => _isInitialized;
}
