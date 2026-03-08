// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_error_parser.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class BaseDataSource {
  HeliumException handleDioError(DioException e, StackTrace s) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _log.severe('DioException occurred', e, s);

        return NetworkException(
          message: 'Connection timeout. Check your internet connection.',
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
            message: 'Access denied. Please login again.',
            code: '403',
            httpStatusCode: 403,
          );
        } else if (statusCode == 400) {
          final parsedError = ApiErrorParser.parse(responseData);
          final errorMessage = parsedError.displayMessage.isNotEmpty
              ? parsedError.displayMessage
              : 'Unknown validation error occurred.';

          _log.severe('Error message: ${e.message}', e, s);

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
        } else {
          String errorMessage = e.response?.statusMessage ?? 'Unknown error';
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
            } catch (_) {
              errorMessage =
                  'Server error: ${e.response?.statusMessage ?? "Unknown error"}';
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
        _log.severe('DioException occurred, cancelled', e, s);

        return NetworkException(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        _log.severe('DioException occurred, connection/network error', e, s);

        if (e.message?.contains('SocketException') ?? false) {
          return NetworkException(
            message: 'No internet connection.',
            code: 'NO_INTERNET',
          );
        }
        return NetworkException(
          message: 'Network error. Check your connection or try again later.',
          code: 'NETWORK_ERROR',
        );

      default:
        _log.severe('DioException occurred, unhandled type: ${e.type}', e, s);

        return NetworkException(
          message: 'Network error. Check your connection or try again later.',
          code: 'NETWORK_ERROR',
        );
    }
  }
}
