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
