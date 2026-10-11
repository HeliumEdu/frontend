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
  /// Falls back to [message] when the parser produced nothing usable, so a
  /// response it cannot read never renders as empty text.
  String get displayMessage {
    final parsed = parsedError?.displayMessage;
    return parsed == null || parsed.isEmpty ? message : parsed;
  }

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

/// A conditional write lost to a newer version saved elsewhere (412).
///
/// [latest] is the item's current JSON as returned by the server, for the
/// caller to reconcile against.
class ConflictException extends HeliumException {
  static const conflictMessage = 'This was changed on another device.';

  final Map<String, dynamic> latest;

  ConflictException({
    required this.latest,
    super.message = conflictMessage,
    super.code = '412',
    super.httpStatusCode = 412,
    super.cause,
  });
}
