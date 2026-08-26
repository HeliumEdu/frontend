import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_error_parser.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class BaseDataSource {
  static const _reloadHint = 'Check your connection, then click "Reload".';
  static const _unreachableMessage = 'Couldn\'t reach Helium. $_reloadHint';
  static const _timedOutMessage = 'Took too long to reach Helium. $_reloadHint';

  HeliumException handleDioError(
    DioException e,
    StackTrace s, {
    String? notFoundEntity,
  }) {
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
        final responseData = e.response?.data;
        final responseType = responseData?.runtimeType;
        _log.info(
          'Dio bad response received, status: $statusCode, dataType: $responseType',
        );

        if (statusCode == 401) {
          return UnauthorizedException(
            message: 'Check your credentials and try again.',
            code: '401',
            httpStatusCode: 401,
          );
        } else if (statusCode == 403) {
          return UnauthorizedException(
            message: 'Access denied. Please sign in again.',
            code: '403',
            httpStatusCode: 403,
          );
        } else if (statusCode == 400) {
          final parsedError = ApiErrorParser.parse(responseData);
          final errorMessage = parsedError.displayMessage.isNotEmpty
              ? parsedError.displayMessage
              : 'Unknown validation error occurred.';

          _log.warning('Validation error, status: $statusCode');

          return ValidationException(
            message: errorMessage,
            code: '400',
            httpStatusCode: 400,
            details: responseData,
            parsedError: parsedError,
          );
        } else if (statusCode == 500) {
          return ServerException(
            message: 'Server error. Please try again later.',
            code: '500',
            httpStatusCode: 500,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            message: '${notFoundEntity ?? 'Item'} not found.',
            details: responseData,
          );
        } else {
          String errorMessage =
              e.response?.statusMessage ?? HeliumException.unexpectedError;
          String? errorCode = statusCode.toString();

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                // Look for common error message keys
                if (responseData.containsKey('message')) {
                  errorMessage = responseData['message'].toString();
                } else if (responseData.containsKey('error')) {
                  errorMessage = responseData['error'].toString();
                } else if (responseData.containsKey('detail')) {
                  errorMessage = responseData['detail'].toString();
                } else {
                  errorMessage = responseData.toString();
                }
                // Extract custom error code if present
                if (responseData.containsKey('code')) {
                  errorCode = responseData['code'].toString();
                }
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (parseError) {
              _log.warning(
                'Failed to parse error response: ${e.response?.statusMessage}',
                parseError,
              );
              errorMessage = HeliumException.unexpectedError;
            }
          }

          return ServerException(
            message: errorMessage,
            code: errorCode,
            httpStatusCode: statusCode,
            details: responseData,
          );
        }

      case DioExceptionType.cancel:
        _log.info('DioException occurred, request cancelled', e, s);

        return NetworkException(
          message: _unreachableMessage,
          code: 'CANCELLED',
        );

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
}
