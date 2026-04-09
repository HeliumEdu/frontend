// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io'
    if (dart.library.html) 'package:heliumapp/core/platform_stub.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

class FeedbackService with WidgetsBindingObserver {
  static const String _keySessionEndedClean = 'feedback_session_ended_clean';
  static const String _keyCleanSessionCount = 'feedback_clean_session_count';
  static const int _cleanSessionThreshold = 2;

  final DioClient _dioClient;
  final PrefService _prefService;
  final InAppReview _inAppReview;

  bool _isInitialized = false;

  static FeedbackService _instance = FeedbackService._internal();

  factory FeedbackService() => _instance;

  FeedbackService._internal()
    : _dioClient = DioClient(),
      _prefService = PrefService(),
      _inAppReview = InAppReview.instance;

  @visibleForTesting
  FeedbackService.forTesting({
    required DioClient dioClient,
    required PrefService prefService,
    required InAppReview inAppReview,
  }) : _dioClient = dioClient,
       _prefService = prefService,
       _inAppReview = inAppReview;

  @visibleForTesting
  static void resetForTesting() {
    _instance = FeedbackService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(FeedbackService instance) {
    _instance = instance;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    if (!kIsWeb) {
      final previousSessionWasClean =
          _prefService.getBool(_keySessionEndedClean) ?? false;
      final currentCount = _prefService.getInt(_keyCleanSessionCount) ?? 0;

      if (previousSessionWasClean) {
        await _prefService.setInt(_keyCleanSessionCount, currentCount + 1);
      } else {
        await _prefService.setInt(_keyCleanSessionCount, 0);
      }

      await _prefService.setBool(_keySessionEndedClean, false);

      WidgetsBinding.instance.addObserver(this);
    }

    _isInitialized = true;
    _log.info('FeedbackService initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _prefService.setBool(_keySessionEndedClean, true);
    }
  }

  Future<void> triggerReviewRequest() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;

    final cleanSessions = _prefService.getInt(_keyCleanSessionCount) ?? 0;
    if (cleanSessions < _cleanSessionThreshold) return;

    final UserSettingsModel? settings;
    try {
      settings = await _dioClient.getSettings();
      if (settings == null || !settings.promptForReview) return;
    } catch (e) {
      _log.warning('Failed to fetch settings for review check: $e');
      return;
    }

    try {
      if (!await _inAppReview.isAvailable()) return;

      await _inAppReview.requestReview();
      _log.info('In-app review requested');
    } catch (e, st) {
      _log.warning('Failed to request in-app review: $e');
      return;
    }

    try {
      await _dioClient.acknowledgeReviewPrompt();
    } catch (e, st) {
      ErrorHelpers.logAndReport('Failed to acknowledge review prompt', e, st);
    }
  }

  bool get isInitialized => _isInitialized;
}
