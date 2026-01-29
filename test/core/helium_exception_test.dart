// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';

void main() {
  group('HeliumException', () {
    test('creates exception with message', () {
      final exception = HeliumException(message: 'Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.code, isNull);
      expect(exception.details, isNull);
    });

    test('creates exception with message and code', () {
      final exception = HeliumException(message: 'Test error', code: '500');
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('500'));
    });

    test('creates exception with all parameters', () {
      final exception = HeliumException(
        message: 'Test error',
        code: '400',
        details: {'field': 'email', 'reason': 'invalid'},
      );
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('400'));
      expect(exception.details, isA<Map<dynamic, dynamic>>());
    });

    test('toString returns message', () {
      final exception = HeliumException(message: 'Error message');
      expect(exception.toString(), equals('Error message'));
    });

    test('implements Exception interface', () {
      final exception = HeliumException(message: 'Test');
      expect(exception, isA<Exception>());
    });
  });

  group('NetworkException', () {
    test('creates network exception with message', () {
      final exception = NetworkException(message: 'Connection timeout');
      expect(exception.message, equals('Connection timeout'));
      expect(exception, isA<HeliumException>());
    });

    test('can be caught as HeliumException', () {
      try {
        throw NetworkException(message: 'No internet');
      } on HeliumException catch (e) {
        expect(e.message, equals('No internet'));
      }
    });

    test('can be caught specifically as NetworkException', () {
      try {
        throw NetworkException(message: 'Timeout');
      } on NetworkException catch (e) {
        expect(e.message, equals('Timeout'));
      }
    });
  });

  group('ServerException', () {
    test('creates server exception with message', () {
      final exception = ServerException(message: 'Internal server error');
      expect(exception.message, equals('Internal server error'));
      expect(exception, isA<HeliumException>());
    });

    test('creates server exception with code', () {
      final exception = ServerException(message: 'Server error', code: '500');
      expect(exception.code, equals('500'));
    });
  });

  group('ValidationException', () {
    test('creates validation exception with message', () {
      final exception = ValidationException(message: 'Field is required');
      expect(exception.message, equals('Field is required'));
      expect(exception, isA<HeliumException>());
    });

    test('creates validation exception with details', () {
      final exception = ValidationException(
        message: 'Validation failed',
        details: {'email': 'Invalid format'},
      );
      expect(exception.details, isA<Map<dynamic, dynamic>>());
    });
  });

  group('NotFoundException', () {
    test('creates not found exception with message', () {
      final exception = NotFoundException(message: 'Resource not found');
      expect(exception.message, equals('Resource not found'));
      expect(exception, isA<HeliumException>());
    });

    test('has default code of 404', () {
      final exception = NotFoundException(message: 'Not found');
      expect(exception.code, equals('404'));
    });

    test('can override default code', () {
      final exception = NotFoundException(message: 'Not found', code: '410');
      expect(exception.code, equals('410'));
    });
  });

  group('UnauthorizedException', () {
    test('creates unauthorized exception with message', () {
      final exception = UnauthorizedException(message: 'Invalid credentials');
      expect(exception.message, equals('Invalid credentials'));
      expect(exception, isA<HeliumException>());
    });

    test('creates unauthorized exception with code', () {
      final exception = UnauthorizedException(
        message: 'Session expired',
        code: '401',
      );
      expect(exception.code, equals('401'));
    });
  });

  group('Exception hierarchy catch behavior', () {
    test('specific exceptions can be caught before base HeliumException', () {
      String caughtType = '';

      try {
        throw ValidationException(message: 'Test');
      } on ValidationException {
        caughtType = 'ValidationException';
      } on HeliumException {
        caughtType = 'HeliumException';
      }

      expect(caughtType, equals('ValidationException'));
    });

    test('HeliumException catches all derived exceptions', () {
      final exceptions = [
        NetworkException(message: 'Network'),
        ServerException(message: 'Server'),
        ValidationException(message: 'Validation'),
        NotFoundException(message: 'Not found'),
        UnauthorizedException(message: 'Unauthorized'),
      ];

      for (final exception in exceptions) {
        try {
          throw exception;
        } on HeliumException catch (e) {
          expect(e, isA<HeliumException>());
        }
      }
    });
  });
}
