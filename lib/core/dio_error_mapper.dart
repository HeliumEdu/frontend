import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_error_parser.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/session_health.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.dio');

class DioErrorMapper {
  DioErrorMapper._();

  static const _retryHint = 'Check your connection and try again.';
  static const _unreachableMessage = 'Couldn\'t reach Helium. $_retryHint';
  static const _timedOutMessage = 'Took too long to reach Helium. $_retryHint';
  static const _serverErrorMessage = 'Server error. Please try again later.';

  static HeliumException map(DioException e, StackTrace s) {
    final responseData = e.response?.data;
    if (e.type == DioExceptionType.badResponse &&
        e.response?.statusCode == 412 &&
        responseData is Map<String, dynamic>) {
      _log.info('Dio precondition failed, the item changed elsewhere');
      return ConflictException(latest: responseData);
    }

    SessionHealth.markTroubled();

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _log.warning('DioException occurred, timeout', e, s);

        return NetworkException(
          message: _timedOutMessage,
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseType = responseData?.runtimeType;
        final summary =
            'Dio bad response received, status: $statusCode, dataType: $responseType';
        if (statusCode == 400) {
          _log.warning(summary);
          final parsedError = ApiErrorParser.parse(responseData);
          final errorMessage = parsedError.displayMessage.isNotEmpty
              ? parsedError.displayMessage
              : _serverErrorMessage;

          return ValidationException(
            message: errorMessage,
            code: '400',
            httpStatusCode: 400,
            details: responseData,
            parsedError: parsedError,
          );
        }

        _log.info(summary);
        final message = serverMessage(responseData) ?? _serverErrorMessage;
        final code = switch (responseData) {
          {'code': final String bodyCode} => bodyCode,
          _ => statusCode.toString(),
        };
        return switch (statusCode) {
          401 => UnauthorizedException(
            message: message,
            code: code,
            httpStatusCode: 401,
            details: responseData,
          ),
          403 => UnauthorizedException(
            message: message,
            code: code,
            httpStatusCode: 403,
            details: responseData,
          ),
          404 => NotFoundException(
            message: message,
            code: code,
            details: responseData,
          ),
          429 => ServerException(
            message: message,
            code: code,
            httpStatusCode: 429,
            details: responseData,
          ),
          500 => ServerException(
            message: message,
            code: code,
            httpStatusCode: 500,
            details: responseData,
          ),
          _ => ServerException(
            message: message,
            code: code,
            httpStatusCode: statusCode,
            details: responseData,
          ),
        };

      case DioExceptionType.connectionError:
        _log.warning('DioException occurred, connection error', e, s);

        return NetworkException(
          message: _unreachableMessage,
          code: 'NETWORK_ERROR',
        );

      case DioExceptionType.unknown:
        _log.severe('DioException occurred, unknown error', e, s);

        return NetworkException(
          message: _unreachableMessage,
          code: 'NETWORK_ERROR',
        );

      default:
        _log.severe('DioException occurred, unhandled type: ${e.type}', e, s);

        return NetworkException(
          message: _unreachableMessage,
          code: 'NETWORK_ERROR',
        );
    }
  }

  /// The user-facing text of a Helium error body, or null when [data] isn't
  /// one (no body, or a load balancer's page): only a JSON object is.
  static String? serverMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    for (final key in const ['message', 'error', 'detail']) {
      if (data[key] case final String text) return text;
    }
    final parsed = ApiErrorParser.parse(data).displayMessage;
    return parsed.isEmpty ? null : parsed;
  }

  /// Server-provided text for 4xx only, with every field error included.
  ///
  /// For a 5xx, callers fall back to their own message, which names the
  /// action that failed.
  static String? clientErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    if (statusCode < 400 || statusCode >= 500) {
      return null;
    }

    final parsedError = ApiErrorParser.parse(e.response?.data);
    return parsedError.displayMessage.isNotEmpty
        ? parsedError.displayMessage
        : null;
  }
}
