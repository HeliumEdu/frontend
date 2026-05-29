// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/api_error_parser.dart';

class HeliumException implements Exception {
  static const unexpectedError = 'An unexpected error occurred.';

  final String message;
  final String? code;
  final int? httpStatusCode;
  final dynamic details;

  /// Parsed error containing field-specific errors and a clean display message
  final ParsedApiError? parsedError;

  /// The original exception this one wraps, if any.
  final Object? cause;

  HeliumException({
    required this.message,
    this.code,
    this.httpStatusCode,
    this.details,
    this.parsedError,
    this.cause,
  });

  /// Returns the user-friendly display message (without field prefixes).
  /// Falls back to [message] if no parsed error is available.
  String get displayMessage => parsedError?.displayMessage ?? message;

  /// Returns the error message for a specific field, or null if none
  String? getFieldError(String fieldName) => parsedError?.getFieldError(fieldName);

  /// Whether this exception has field-specific errors
  bool get hasFieldErrors => parsedError?.hasFieldErrors ?? false;

  @override
  String toString() => message;
}

class NetworkException extends HeliumException {
  NetworkException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
    super.parsedError,
    super.cause,
  });
}

class ServerException extends HeliumException {
  ServerException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
    super.parsedError,
    super.cause,
  });
}

class ValidationException extends HeliumException {
  ValidationException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
    super.parsedError,
    super.cause,
  });
}

class NotFoundException extends HeliumException {
  NotFoundException({
    required super.message,
    super.code = '404',
    super.httpStatusCode = 404,
    super.details,
    super.parsedError,
    super.cause,
  });
}

class UnauthorizedException extends HeliumException {
  UnauthorizedException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
    super.parsedError,
    super.cause,
  });
}
