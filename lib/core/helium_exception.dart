// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class HeliumException implements Exception {
  final String message;
  final String? code;
  final int? httpStatusCode;
  final dynamic details;

  HeliumException({
    required this.message,
    this.code,
    this.httpStatusCode,
    this.details,
  });

  @override
  String toString() => message;
}

class NetworkException extends HeliumException {
  NetworkException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
  });
}

class ServerException extends HeliumException {
  ServerException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
  });
}

class ValidationException extends HeliumException {
  ValidationException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
  });
}

class NotFoundException extends HeliumException {
  NotFoundException({
    required super.message,
    super.code = '404',
    super.httpStatusCode = 404,
    super.details,
  });
}

class UnauthorizedException extends HeliumException {
  UnauthorizedException({
    required super.message,
    super.code,
    super.httpStatusCode,
    super.details,
  });
}
