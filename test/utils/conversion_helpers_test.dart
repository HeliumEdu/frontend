// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

void main() {
  group('HeliumConversion', () {
    group('toDouble', () {
      test('returns null for null input', () {
        expect(HeliumConversion.toDouble(null), isNull);
      });

      test('converts int to double', () {
        expect(HeliumConversion.toDouble(42), 42.0);
      });

      test('returns double as-is', () {
        expect(HeliumConversion.toDouble(3.14), 3.14);
      });

      test('parses string to double', () {
        expect(HeliumConversion.toDouble('3.14'), 3.14);
      });

      test('parses integer string to double', () {
        expect(HeliumConversion.toDouble('42'), 42.0);
      });

      test('returns null for invalid string', () {
        expect(HeliumConversion.toDouble('not a number'), isNull);
      });

      test('returns null for empty string', () {
        expect(HeliumConversion.toDouble(''), isNull);
      });

      test('returns null for non-numeric types', () {
        expect(HeliumConversion.toDouble([1, 2, 3]), isNull);
      });

      test('handles negative numbers', () {
        expect(HeliumConversion.toDouble(-5), -5.0);
        expect(HeliumConversion.toDouble('-5.5'), -5.5);
      });

      test('handles zero', () {
        expect(HeliumConversion.toDouble(0), 0.0);
        expect(HeliumConversion.toDouble('0'), 0.0);
      });
    });

    group('toInt', () {
      test('returns null for null input', () {
        expect(HeliumConversion.toInt(null), isNull);
      });

      test('returns int as-is', () {
        expect(HeliumConversion.toInt(42), 42);
      });

      test('converts double to int (truncates)', () {
        expect(HeliumConversion.toInt(3.14), 3);
        expect(HeliumConversion.toInt(3.99), 3);
      });

      test('parses string to int', () {
        expect(HeliumConversion.toInt('42'), 42);
      });

      test('returns null for decimal string', () {
        expect(HeliumConversion.toInt('3.14'), isNull);
      });

      test('returns null for invalid string', () {
        expect(HeliumConversion.toInt('not a number'), isNull);
      });

      test('returns null for empty string', () {
        expect(HeliumConversion.toInt(''), isNull);
      });

      test('returns null for non-numeric types', () {
        expect(HeliumConversion.toInt({'key': 'value'}), isNull);
      });

      test('handles negative numbers', () {
        expect(HeliumConversion.toInt(-5), -5);
        expect(HeliumConversion.toInt('-5'), -5);
      });

      test('handles zero', () {
        expect(HeliumConversion.toInt(0), 0);
        expect(HeliumConversion.toInt('0'), 0);
      });
    });
  });
}
