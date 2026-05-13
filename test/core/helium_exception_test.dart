// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';

void main() {
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

    test('cause preserves the original typed exception when wrapping', () {
      // Simulates a data source's generic catch wrapping a typed exception:
      // the public message stays generic, but `cause` lets callers introspect
      // what was actually thrown (e.g. self-heal logic in the bloc layer).
      final original = NotFoundException(message: 'No Schedule found for Course');

      try {
        try {
          throw original;
        } catch (e) {
          throw HeliumException(
            message: 'An unexpected error occurred.',
            cause: e,
          );
        }
      } on HeliumException catch (e) {
        expect(e.message, equals('An unexpected error occurred.'));
        expect(e.cause, isA<NotFoundException>());
        expect(e.cause, same(original));
      }
    });

    test('cause is null when not provided', () {
      final exception = HeliumException(message: 'Plain');
      expect(exception.cause, isNull);
    });
  });
}
