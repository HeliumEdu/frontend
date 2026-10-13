import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/session_health.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

class FeedbackService with WidgetsBindingObserver {
  static const String _keySessionEndedClean = 'feedback_session_ended_clean';
  static const String _keyCleanSessionCount = 'feedback_clean_session_count';
  static const int _cleanSessionThreshold = 2;
  static const Duration _reviewRequestDelay = Duration(seconds: 4);

  final DioClient _dioClient;
  final PrefService _prefService;
  final InAppReview _inAppReview;

  bool _isInitialized = false;
  Timer? _pendingReviewRequest;

  static final FeedbackService _instance = FeedbackService._internal();

  factory FeedbackService() => _instance;

  FeedbackService._internal()
    : _dioClient = DioClient(),
      _prefService = PrefService(),
      _inAppReview = InAppReview.instance;

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
      _cancelPendingReviewRequest();
      _prefService.setBool(_keySessionEndedClean, true);
    } else if (state == AppLifecycleState.resumed) {
      _prefService.setBool(_keySessionEndedClean, false);
    }
  }

  /// Requests a review once completions have stopped for
  /// [_reviewRequestDelay], so a run of completions is not interrupted; each
  /// call restarts the wait. Backgrounding the app drops the pending request
  /// unacknowledged, leaving the user eligible next time.
  void scheduleReviewRequest() {
    if (kIsWeb) return;

    _cancelPendingReviewRequest();
    _pendingReviewRequest = Timer(_reviewRequestDelay, _requestReview);
  }

  void _cancelPendingReviewRequest() {
    _pendingReviewRequest?.cancel();
    _pendingReviewRequest = null;
  }

  Future<void> _requestReview() async {
    _pendingReviewRequest = null;

    if (SessionHealth.isTroubled) return;

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
    } catch (e) {
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
