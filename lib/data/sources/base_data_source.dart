// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class BaseDataSource {
  HeliumException handleDioError(DioException e, StackTrace s) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        log.severe('DioException occurred', e, s);

        return NetworkException(
          message: 'Connection timeout. Check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        log.info('Dio bad response received, status: $statusCode, data: $responseData');

        if (statusCode == 401) {
          return UnauthorizedException(
            message: 'Check your credentials and try again.',
            code: '401',
          );
        } else if (statusCode == 400) {
          String errorMessage = 'Unknown validation error occurred.';

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                final errors = <String>[];
                responseData.forEach((key, value) {
                  if (value is List) {
                    for (var msg in value) {
                      errors.add('$key: $msg');
                    }
                  } else {
                    errors.add('$key: $value');
                  }
                });
                if (errors.isNotEmpty) {
                  errorMessage = errors.join('\n');
                }
              } else if (responseData is List<dynamic>) {
                final errors = <String>[];
                for (var value in responseData) {
                  errors.add(value);
                }
                if (errors.isNotEmpty) {
                  errorMessage = errors.join('\n');
                }
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (e) {
              errorMessage = 'Validation error: ${responseData.toString()}';
            }
          }

          log.severe('Error message: ${e.message}', e, s);

          return ValidationException(
            message: errorMessage,
            code: '400',
            details: responseData,
          );
        } else if (statusCode == 500) {
          return ServerException(
            message: 'Server error. Please try again later.',
            code: '500',
          );
        } else {
          String errorMessage = e.response?.statusMessage ?? 'Unknown error';

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
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (_) {
              errorMessage =
                  'Server error: ${e.response?.statusMessage ?? "Unknown error"}';
            }
          }

          return ServerException(
            message: errorMessage,
            code: statusCode.toString(),
            details: responseData,
          );
        }

      case DioExceptionType.cancel:
        log.severe('DioException occurred, cancelled', e, s);

        return NetworkException(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
        log.severe('DioException occurred, unknown', e, s);

        if (e.message?.contains('SocketException') ?? false) {
          return NetworkException(
            message: 'No internet connection',
            code: 'NO_INTERNET',
          );
        }
        return NetworkException(
          message: 'Network error. Check your connection or try again later.',
          code: 'UNKNOWN',
        );

      default:
        log.severe('DioException occurred, unknown', e, s);

        return NetworkException(
          message: 'Network error: ${e.message}',
          code: 'NETWORK_ERROR',
        );
    }
  }
}
