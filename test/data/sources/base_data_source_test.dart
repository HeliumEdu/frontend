// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';

import '../../mocks/mock_dio.dart';

/// Concrete implementation for testing the abstract BaseDataSource.
class TestDataSource extends BaseDataSource {}

void main() {
  late TestDataSource dataSource;

  setUp(() {
    dataSource = TestDataSource();
  });

  group('BaseDataSource', () {
    group('handleDioError', () {
      group('timeout errors', () {
        test('returns NetworkException for connectionTimeout', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.connectionTimeout,
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('TIMEOUT'));
          expect(result.message, contains('timeout'));
        });

        test('returns NetworkException for sendTimeout', () {
          // GIVEN
          final error = givenDioException(type: DioExceptionType.sendTimeout);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('TIMEOUT'));
        });

        test('returns NetworkException for receiveTimeout', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.receiveTimeout,
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('TIMEOUT'));
        });
      });

      group('401 Unauthorized', () {
        test('returns UnauthorizedException for 401 response', () {
          // GIVEN
          final error = givenUnauthorizedException();

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<UnauthorizedException>());
          expect(result.code, equals('401'));
          expect(result.message, contains('credentials'));
        });
      });

      group('400 Validation errors', () {
        test('parses Map validation errors with List values', () {
          // GIVEN
          final error = givenValidationException({
            'username': ['Username is required', 'Username must be unique'],
            'email': ['Invalid email format'],
          });

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.code, equals('400'));
          expect(result.message, contains('username'));
          expect(result.message, contains('email'));
        });

        test('parses Map validation errors with String values', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 400,
            responseData: {'field': 'Error message'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.message, contains('field'));
          expect(result.message, contains('Error message'));
        });

        test('parses List validation errors', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 400,
            responseData: ['Error 1', 'Error 2'],
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.message, contains('Error 1'));
          expect(result.message, contains('Error 2'));
        });

        test('parses String validation error', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 400,
            responseData: 'Simple error message',
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.message, equals('Simple error message'));
        });

        test('handles null response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 400,
            responseData: null,
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.message, contains('Unknown validation error'));
        });

        test('includes details in ValidationException', () {
          // GIVEN
          final responseData = {'username': ['Required']};
          final error = givenValidationException(responseData);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.details, equals(responseData));
        });
      });

      group('500 Server errors', () {
        test('returns ServerException for 500 response', () {
          // GIVEN
          final error = givenServerException();

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.code, equals('500'));
          expect(result.message, contains('Server error'));
        });
      });

      group('other status codes', () {
        test('extracts message from response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 403,
            responseData: {'message': 'Access denied'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.code, equals('403'));
          expect(result.message, equals('Access denied'));
        });

        test('extracts error from response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 404,
            responseData: {'error': 'Resource not found'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Resource not found'));
        });

        test('extracts detail from response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 429,
            responseData: {'detail': 'Rate limit exceeded'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Rate limit exceeded'));
        });

        test('handles String response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 502,
            responseData: 'Bad Gateway',
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Bad Gateway'));
        });

        test('falls back to status message when no response data', () {
          // GIVEN
          final error = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: ''),
            response: Response(
              statusCode: 418,
              statusMessage: "I'm a teapot",
              requestOptions: RequestOptions(path: ''),
            ),
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals("I'm a teapot"));
        });

        test('includes details in ServerException', () {
          // GIVEN
          final responseData = {'detail': 'Error', 'extra': 'info'};
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 422,
            responseData: responseData,
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.details, equals(responseData));
        });
      });

      group('cancel errors', () {
        test('returns NetworkException for cancelled request', () {
          // GIVEN
          final error = givenDioException(type: DioExceptionType.cancel);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('CANCELLED'));
          expect(result.message, contains('cancelled'));
        });
      });

      group('unknown errors', () {
        test('returns NetworkException with NO_INTERNET for SocketException', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.unknown,
            message: 'SocketException: Connection refused',
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('NO_INTERNET'));
          expect(result.message, contains('No internet'));
        });

        test('returns NetworkException with UNKNOWN for other unknown errors', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.unknown,
            message: 'Some other error',
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('UNKNOWN'));
        });

        test('handles null message in unknown error', () {
          // GIVEN
          final error = DioException(
            type: DioExceptionType.unknown,
            requestOptions: RequestOptions(path: ''),
            message: null,
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('UNKNOWN'));
        });
      });

      group('default case', () {
        test('returns NetworkException for connectionError type', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.connectionError,
            message: 'Connection error',
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('NETWORK_ERROR'));
        });

        test('returns NetworkException for badCertificate type', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badCertificate,
            message: 'Bad certificate',
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('NETWORK_ERROR'));
        });
      });
    });
  });
}
