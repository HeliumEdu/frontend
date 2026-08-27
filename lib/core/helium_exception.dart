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
