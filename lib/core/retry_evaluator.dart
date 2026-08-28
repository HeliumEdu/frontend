import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:heliumapp/core/api_url.dart';

class HeliumRetryEvaluator {
  static const Set<String> _retryableMethods = {'GET', 'HEAD', 'OPTIONS'};

  static const Duration maxTotalWait = Duration(seconds: 30);
  static const String deadlineKey = 'helium_retry_deadline';

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

  static DateTime deadlineFor(RequestOptions options) =>
      options.extra.putIfAbsent(
            deadlineKey,
            () => DateTime.now().add(maxTotalWait),
          )
          as DateTime;

  /// Refresh tokens rotate, so retrying only helps when the request never
  /// reached the app.
  static bool _isRetryableTokenRefresh(DioException error) =>
      error.response == null &&
      error.requestOptions.path.contains(ApiUrl.authTokenRefreshUrl);

  FutureOr<bool> evaluate(DioException error, int attempt) {
    final options = error.requestOptions;

    if (!_retryableMethods.contains(options.method.toUpperCase()) &&
        !_isRetryableTokenRefresh(error)) {
      return false;
    }

    // No route to the host, so another attempt only delays the failure. Token
    // refresh keeps its retries: one that never reached the server is worth
    // repeating.
    if (error.type == DioExceptionType.connectionError &&
        !_isRetryableTokenRefresh(error)) {
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
}
