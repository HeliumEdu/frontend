// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

/// Test model implementing BaseModel for IdOrEntity tests.
class TestModel extends BaseTitledModel {
  final String description;

  TestModel({required super.id, required super.title, this.description = ''});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

void main() {
  group('HeliumConversion', () {
    group('toDouble', () {
      test('converts numeric types to double', () {
        expect(HeliumConversion.toDouble(42), 42.0);
        expect(HeliumConversion.toDouble(3.14), 3.14);
        expect(HeliumConversion.toDouble('3.14'), 3.14);
        expect(HeliumConversion.toDouble('42'), 42.0);
        expect(HeliumConversion.toDouble(-5), -5.0);
        expect(HeliumConversion.toDouble('-5.5'), -5.5);
        expect(HeliumConversion.toDouble(0), 0.0);
      });

      test('returns null for invalid input', () {
        expect(HeliumConversion.toDouble(null), isNull);
        expect(HeliumConversion.toDouble(''), isNull);
        expect(HeliumConversion.toDouble('not a number'), isNull);
        expect(HeliumConversion.toDouble([1, 2, 3]), isNull);
      });
    });

    group('toInt', () {
      test('converts to int', () {
        expect(HeliumConversion.toInt(42), 42);
        expect(HeliumConversion.toInt(3.14), 3); // Truncates
        expect(HeliumConversion.toInt('42'), 42);
        expect(HeliumConversion.toInt(-5), -5);
        expect(HeliumConversion.toInt('-5'), -5);
        expect(HeliumConversion.toInt(0), 0);
      });

      test('returns null for invalid input', () {
        expect(HeliumConversion.toInt(null), isNull);
        expect(HeliumConversion.toInt(''), isNull);
        expect(HeliumConversion.toInt('3.14'), isNull); // No decimal strings
        expect(HeliumConversion.toInt('not a number'), isNull);
        expect(HeliumConversion.toInt({'key': 'value'}), isNull);
      });
    });

    group('idOrEntityFrom', () {
      test('creates IdOrEntity from int', () {
        // WHEN
        final result = HeliumConversion.idOrEntityFrom<TestModel>(
          42,
          TestModel.fromJson,
        );

        // THEN
        expect(result.id, equals(42));
        expect(result.entity, isNull);
      });

      test('creates IdOrEntity from String id', () {
        // WHEN
        final result = HeliumConversion.idOrEntityFrom<TestModel>(
          '123',
          TestModel.fromJson,
        );

        // THEN
        expect(result.id, equals(123));
        expect(result.entity, isNull);
      });

      test('creates IdOrEntity from Map with entity', () {
        // GIVEN
        final data = {'id': 1, 'title': 'Test Item', 'description': 'Desc'};

        // WHEN
        final result = HeliumConversion.idOrEntityFrom<TestModel>(
          data,
          TestModel.fromJson,
        );

        // THEN
        expect(result.id, equals(1));
        expect(result.entity, isNotNull);
        expect(result.entity!.title, equals('Test Item'));
        expect(result.entity!.description, equals('Desc'));
      });

      test('throws HeliumException for invalid data format', () {
        // WHEN/THEN
        expect(
          () => HeliumConversion.idOrEntityFrom<TestModel>(
            ['invalid'],
            TestModel.fromJson,
          ),
          throwsA(isA<HeliumException>()),
        );
      });
    });

    group('idOrEntityListFrom', () {
      test('creates list from mixed id types and entities', () {
        final result = HeliumConversion.idOrEntityListFrom<TestModel>(
          [
            1, // int id
            '10', // String id
            {'id': 2, 'title': 'Item 2'}, // entity map
          ],
          TestModel.fromJson,
        );

        expect(result.length, 3);
        expect(result[0].id, 1);
        expect(result[0].entity, isNull);
        expect(result[1].id, 10);
        expect(result[1].entity, isNull);
        expect(result[2].id, 2);
        expect(result[2].entity!.title, 'Item 2');
      });

      test('returns empty list for empty input', () {
        expect(HeliumConversion.idOrEntityListFrom<TestModel>([], TestModel.fromJson), isEmpty);
      });
    });
  });
}
