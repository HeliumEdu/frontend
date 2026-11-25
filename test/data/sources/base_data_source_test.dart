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
      group('rate limiting', () {
        DioException givenTooManyRequests({String? retryAfter, Object? data}) {
          final requestOptions = RequestOptions(path: '');
          return DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              statusCode: 429,
              requestOptions: requestOptions,
              data: data,
              headers: Headers.fromMap({
                if (retryAfter != null) 'retry-after': [retryAfter],
              }),
            ),
          );
        }

        test('shows the server text as-is', () {
          // GIVEN
          final error = givenTooManyRequests(
            retryAfter: '3540',
            data: {'detail': 'Request was throttled. Try again in 3540 seconds.', 'code': 'throttled'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.httpStatusCode, 429);
          expect(result.code, 'throttled');
          expect(result.message, 'Request was throttled. Try again in 3540 seconds.');
        });

        test('uses the server error text without a Helium body', () {
          // GIVEN
          final error = givenTooManyRequests(retryAfter: '3540', data: '<html>Too Many Requests</html>');

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result.code, '429');
          expect(result.message, 'Server error. Please try again later.');
        });
      });

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
          expect(result.message, contains('Took too long'));
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
        test('returns UnauthorizedException with the server text and code', () {
          // GIVEN
          final error = givenDioException(
            statusCode: 401,
            responseData: {
              'detail': 'Check your credentials and try again.',
              'code': 'credentials_invalid',
            },
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<UnauthorizedException>());
          expect(result.httpStatusCode, equals(401));
          expect(result.code, equals('credentials_invalid'));
          expect(result.message, equals('Check your credentials and try again.'));
        });

        test('falls back to the status as code for a body without one', () {
          // GIVEN
          final error = givenUnauthorizedException();

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result.code, equals('401'));
          expect(result.message, equals('Unauthorized'));
        });

        test('uses the server error text without a Helium body', () {
          // GIVEN
          final error = givenDioException(statusCode: 401);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<UnauthorizedException>());
          expect(result.code, equals('401'));
          expect(result.message, equals('Server error. Please try again later.'));
        });
      });

      group('403 Forbidden', () {
        test('returns UnauthorizedException for 403 response', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 403,
            responseData: {'detail': 'Access denied'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<UnauthorizedException>());
          expect(result.code, equals('403'));
          expect(result.message, equals('Access denied'));
        });

        test('keeps an inactive account\'s code and email for the resend flow', () {
          // GIVEN
          final responseData = {
            'detail': "Your account isn't active yet.",
            'code': 'account_inactive',
            'email': 'student@example.com',
          };
          final error = givenDioException(statusCode: 403, responseData: responseData);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<UnauthorizedException>());
          expect(result.code, equals('account_inactive'));
          expect(result.message, equals("Your account isn't active yet."));
          expect(result.details, equals(responseData));
        });

        test('uses the server error text for a page that is not a Helium body', () {
          // GIVEN
          final error = givenDioException(statusCode: 403, responseData: '<html>Forbidden</html>');

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result.code, equals('403'));
          expect(result.message, equals('Server error. Please try again later.'));
        });
      });

      group('400 Validation errors', () {
        test('parses Map validation errors with List values', () {
          // GIVEN
          final error = givenValidationException({
            'email': ['Email is required', 'Email must be unique'],
            'password': ['Password is too short'],
          });

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.code, equals('400'));
          // Message should contain the error text without field prefixes
          expect(result.message, contains('Email is required'));
          expect(result.message, contains('Password is too short'));
          // Field errors should be accessible via parsedError
          expect(result.parsedError, isNotNull);
          expect(result.parsedError!.getFieldError('email'), equals('Email is required'));
          expect(result.parsedError!.getFieldError('password'), equals('Password is too short'));
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
          // Message should contain the error text without field prefix
          expect(result.message, contains('Error message'));
          // Field error should be accessible via parsedError
          expect(result.parsedError, isNotNull);
          expect(result.parsedError!.getFieldError('field'), equals('Error message'));
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
          expect(result.message, equals('Server error. Please try again later.'));
        });

        test('includes details in ValidationException', () {
          // GIVEN
          final responseData = {
            'email': ['Required'],
          };
          final error = givenValidationException(responseData);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ValidationException>());
          expect(result.details, equals(responseData));
        });
      });

      group('500 Server errors', () {
        test('returns ServerException with the server text', () {
          // GIVEN
          final error = givenServerException();

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.code, equals('500'));
          expect(result.message, equals('Internal Server Error'));
        });

        test('uses the server error text without a Helium body', () {
          // GIVEN
          final error = givenDioException(statusCode: 500, responseData: '<html>Internal Server Error</html>');

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Server error. Please try again later.'));
        });
      });

      group('404 Not Found', () {
        test('returns NotFoundException with the server text and code', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 404,
            responseData: {'detail': 'Group not found.', 'code': 'not_found'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NotFoundException>());
          expect(result.code, equals('not_found'));
          expect(result.message, equals('Group not found.'));
        });

        test('uses the server error text without a Helium body', () {
          // GIVEN
          final error = givenDioException(statusCode: 404);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NotFoundException>());
          expect(result.code, equals('404'));
          expect(result.message, equals('Server error. Please try again later.'));
        });
      });

      group('other status codes', () {
        test('extracts message from response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 422,
            responseData: {'message': 'Unprocessable entity'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.code, equals('422'));
          expect(result.message, equals('Unprocessable entity'));
        });

        test('extracts error from response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 409,
            responseData: {'error': 'Resource conflict'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Resource conflict'));
        });

        test('extracts detail from response data', () {
          // GIVEN
          final error = givenDioException(
            type: DioExceptionType.badResponse,
            statusCode: 405,
            responseData: {'detail': 'Method "PATCH" not allowed.'},
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Method "PATCH" not allowed.'));
        });

        test('uses the server error text for a page that is not a Helium body', () {
          // GIVEN
          final error = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: ''),
            response: Response(
              statusCode: 502,
              statusMessage: 'Bad Gateway',
              data: '<html><body>502 Bad Gateway</body></html>',
              requestOptions: RequestOptions(path: ''),
            ),
          );

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<ServerException>());
          expect(result.message, equals('Server error. Please try again later.'));
        });

        test('uses the server error text when there is no response data', () {
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
          expect(result.message, equals('Server error. Please try again later.'));
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
        test('falls through to the generic network error', () {
          // GIVEN
          final error = givenDioException(type: DioExceptionType.cancel);

          // WHEN
          final result = dataSource.handleDioError(error, StackTrace.current);

          // THEN
          expect(result, isA<NetworkException>());
          expect(result.code, equals('NETWORK_ERROR'));
          expect(result.message, contains('try again'));
        });
      });

      group('unknown errors', () {
        test(
          'returns NetworkException with NETWORK_ERROR for SocketException',
          () {
            // GIVEN
            final error = givenDioException(
              type: DioExceptionType.unknown,
              message: 'SocketException: Connection refused',
            );

            // WHEN
            final result = dataSource.handleDioError(error, StackTrace.current);

            // THEN
            expect(result, isA<NetworkException>());
            expect(result.code, equals('NETWORK_ERROR'));
            expect(result.message, contains('try again'));
          },
        );

        test(
          'returns NetworkException with NETWORK_ERROR for other unknown errors',
          () {
            // GIVEN
            final error = givenDioException(
              type: DioExceptionType.unknown,
              message: 'Some other error',
            );

            // WHEN
            final result = dataSource.handleDioError(error, StackTrace.current);

            // THEN
            expect(result, isA<NetworkException>());
            expect(result.code, equals('NETWORK_ERROR'));
          },
        );

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
          expect(result.code, equals('NETWORK_ERROR'));
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

    group('conditional writes', () {
      test('maps a 412 with a body to ConflictException carrying the latest item', () {
        // GIVEN
        final latest = {'id': 7, 'title': 'Changed elsewhere'};
        final error = givenDioException(statusCode: 412, responseData: latest);

        // WHEN
        final result = dataSource.handleDioError(error, StackTrace.current);

        // THEN
        expect(result, isA<ConflictException>());
        expect((result as ConflictException).latest, equals(latest));
        expect(result.httpStatusCode, equals(412));
      });

      test('maps a 412 without a JSON body to a ServerException', () {
        // GIVEN
        final error = givenDioException(statusCode: 412, responseData: 'oops');

        // WHEN
        final result = dataSource.handleDioError(error, StackTrace.current);

        // THEN
        expect(result, isA<ServerException>());
      });

      test('ifMatchOptions sends the version as If-Match', () {
        // WHEN
        final options = dataSource.ifMatchOptions('2026-10-07T12:00:00.123456Z');

        // THEN
        expect(options?.headers?['If-Match'], equals('2026-10-07T12:00:00.123456Z'));
      });

      test('ifMatchOptions sends nothing without a version', () {
        // WHEN
        final options = dataSource.ifMatchOptions(null);

        // THEN
        expect(options, isNull, reason: 'No version means an unconditional write');
      });
    });
  });
}
