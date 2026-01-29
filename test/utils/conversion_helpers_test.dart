// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

/// Test model implementing BaseModel for IdOrEntity tests.
class TestModel extends BaseModel {
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
      test('creates list of IdOrEntity from int ids', () {
        // GIVEN
        final data = [1, 2, 3];

        // WHEN
        final result = HeliumConversion.idOrEntityListFrom<TestModel>(
          data,
          TestModel.fromJson,
        );

        // THEN
        expect(result.length, equals(3));
        expect(result[0].id, equals(1));
        expect(result[1].id, equals(2));
        expect(result[2].id, equals(3));
        expect(result.every((e) => e.entity == null), isTrue);
      });

      test('creates list of IdOrEntity from String ids', () {
        // GIVEN
        final data = ['10', '20', '30'];

        // WHEN
        final result = HeliumConversion.idOrEntityListFrom<TestModel>(
          data,
          TestModel.fromJson,
        );

        // THEN
        expect(result.length, equals(3));
        expect(result[0].id, equals(10));
        expect(result[1].id, equals(20));
        expect(result[2].id, equals(30));
      });

      test('creates list of IdOrEntity from Maps with entities', () {
        // GIVEN
        final data = [
          {'id': 1, 'title': 'Item 1'},
          {'id': 2, 'title': 'Item 2'},
        ];

        // WHEN
        final result = HeliumConversion.idOrEntityListFrom<TestModel>(
          data,
          TestModel.fromJson,
        );

        // THEN
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].entity!.title, equals('Item 1'));
        expect(result[1].id, equals(2));
        expect(result[1].entity!.title, equals('Item 2'));
      });

      test('handles mixed int and Map data', () {
        // GIVEN
        final data = [
          1,
          {'id': 2, 'title': 'Item 2'},
          3,
        ];

        // WHEN
        final result = HeliumConversion.idOrEntityListFrom<TestModel>(
          data,
          TestModel.fromJson,
        );

        // THEN
        expect(result.length, equals(3));
        expect(result[0].id, equals(1));
        expect(result[0].entity, isNull);
        expect(result[1].id, equals(2));
        expect(result[1].entity, isNotNull);
        expect(result[2].id, equals(3));
        expect(result[2].entity, isNull);
      });

      test('returns empty list for empty input', () {
        // WHEN
        final result = HeliumConversion.idOrEntityListFrom<TestModel>(
          [],
          TestModel.fromJson,
        );

        // THEN
        expect(result, isEmpty);
      });
    });
  });

  group('IdOrEntity', () {
    group('equality', () {
      test('two IdOrEntity with same id are equal', () {
        // GIVEN
        final a = IdOrEntity<TestModel>(id: 1);
        final b = IdOrEntity<TestModel>(id: 1);

        // THEN
        expect(a, equals(b));
      });

      test('IdOrEntity equals its id value', () {
        // GIVEN
        final entity = IdOrEntity<TestModel>(id: 42);

        // THEN
        expect(entity.id == 42, isTrue);
      });

      test('two IdOrEntity with different ids are not equal', () {
        // GIVEN
        final a = IdOrEntity<TestModel>(id: 1);
        final b = IdOrEntity<TestModel>(id: 2);

        // THEN
        expect(a, isNot(equals(b)));
      });

      test('IdOrEntity with entity equals one without if same id', () {
        // GIVEN
        final withEntity = IdOrEntity<TestModel>(
          id: 1,
          entity: TestModel(id: 1, title: 'Test'),
        );
        final withoutEntity = IdOrEntity<TestModel>(id: 1);

        // THEN
        expect(withEntity, equals(withoutEntity));
      });
    });

    group('hashCode', () {
      test('same id produces same hashCode', () {
        // GIVEN
        final a = IdOrEntity<TestModel>(id: 1);
        final b = IdOrEntity<TestModel>(id: 1);

        // THEN
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}
