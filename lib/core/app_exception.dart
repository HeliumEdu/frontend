// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException({required this.message, this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({required super.message, super.code, super.details});
}

class ServerException extends AppException {
  ServerException({required super.message, super.code, super.details});
}

class ValidationException extends AppException {
  ValidationException({required super.message, super.code, super.details});
}

class UnauthorizedException extends AppException {
  UnauthorizedException({required super.message, super.code, super.details});
}
