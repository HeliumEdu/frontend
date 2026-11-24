import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:heliumapp/core/api_url.dart';

class HeliumRetryEvaluator {
  static const Set<String> _retryableMethods = {'GET', 'HEAD', 'OPTIONS'};
  static DateTime? _never() => null;

  static const Duration maxTotalWait = Duration(seconds: 30);
  static const String deadlineKey = 'helium_retry_deadline';
  static const String suspensionRestartKey = 'helium_retry_suspension_restart';

  static const Set<int> retryableStatuses = {
    HttpStatus.requestTimeout,
    HttpStatus.internalServerError,
    HttpStatus.badGateway,
    HttpStatus.serviceUnavailable,
    HttpStatus.gatewayTimeout,
  };

  final DefaultRetryEvaluator _delegate = DefaultRetryEvaluator(
    retryableStatuses,
  );
  final DateTime? Function() _lastBackgroundedAt;

  HeliumRetryEvaluator({DateTime? Function()? lastBackgroundedAt})
    : _lastBackgroundedAt = lastBackgroundedAt ?? _never;

  static DateTime deadlineFor(RequestOptions options) =>
      options.extra.putIfAbsent(
            deadlineKey,
            () => DateTime.now().add(maxTotalWait),
          )
          as DateTime;

  FutureOr<bool> evaluate(DioException error, int attempt) {
    final options = error.requestOptions;

    if (!_retryableMethods.contains(options.method.toUpperCase()) &&
        !_isRetryableTokenRefresh(error)) {
      return false;
    }

    final suspended = _restartAfterSuspension(options);

    // No route to the host, so another attempt only delays the failure. Token
    // refresh keeps its retries: one that never reached the server is worth
    // repeating, as is one whose connection the OS dropped while suspended.
    if (error.type == DioExceptionType.connectionError &&
        !_isRetryableTokenRefresh(error) &&
        !suspended) {
      return false;
    }

    final remaining = deadlineFor(options).difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return false;
    }

    options.connectTimeout = remaining;
    options.sendTimeout = remaining;
    options.receiveTimeout = remaining;

    return _delegate.evaluate(error, attempt);
  }

  static bool _isRetryableTokenRefresh(DioException error) =>
      error.response == null &&
      error.requestOptions.path.contains(ApiUrl.authTokenRefreshUrl);

  bool _restartAfterSuspension(RequestOptions options) {
    if (options.extra[suspensionRestartKey] == true) return false;
    final backgroundedAt = _lastBackgroundedAt();
    final sentAt = deadlineFor(options).subtract(maxTotalWait);
    if (backgroundedAt == null || !backgroundedAt.isAfter(sentAt)) {
      return false;
    }
    options.extra[suspensionRestartKey] = true;
    options.extra[deadlineKey] = DateTime.now().add(maxTotalWait);
    return true;
  }
}
