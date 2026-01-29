// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

/// Mock implementation of [Dio] for testing data sources.
class MockDio extends Mock implements Dio {}

/// Creates a successful [Response] with the given data and status code.
Response<T> givenSuccessResponse<T>(T data, {int statusCode = 200}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: ''),
  );
}

/// Creates a [DioException] for testing error handling.
DioException givenDioException({
  DioExceptionType type = DioExceptionType.badResponse,
  int? statusCode,
  dynamic responseData,
  String? message,
}) {
  return DioException(
    type: type,
    requestOptions: RequestOptions(path: ''),
    response: statusCode != null
        ? Response(
            statusCode: statusCode,
            data: responseData,
            requestOptions: RequestOptions(path: ''),
          )
        : null,
    message: message,
  );
}

/// Creates a 401 Unauthorized [DioException].
DioException givenUnauthorizedException({String? message}) {
  return givenDioException(
    type: DioExceptionType.badResponse,
    statusCode: 401,
    responseData: {'detail': message ?? 'Unauthorized'},
    message: message ?? 'Unauthorized',
  );
}

/// Creates a 400 Validation Error [DioException].
DioException givenValidationException(Map<String, dynamic> errors) {
  return givenDioException(
    type: DioExceptionType.badResponse,
    statusCode: 400,
    responseData: errors,
    message: 'Validation error',
  );
}

/// Creates a 500 Server Error [DioException].
DioException givenServerException({String? message}) {
  return givenDioException(
    type: DioExceptionType.badResponse,
    statusCode: 500,
    responseData: {'detail': message ?? 'Internal Server Error'},
    message: message ?? 'Internal Server Error',
  );
}

/// Creates a Network/Timeout [DioException].
DioException givenNetworkException({
  DioExceptionType type = DioExceptionType.connectionTimeout,
}) {
  return givenDioException(type: type, message: 'Network error');
}
