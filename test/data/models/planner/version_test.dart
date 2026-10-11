import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';

import '../../../helpers/note_helper.dart';
import '../../../helpers/planner_helper.dart';

void main() {
  const version = '2026-10-07T12:00:00.123456Z';

  group('version', () {
    test('keeps updated_at as the raw string', () {
      // GIVEN
      final json = givenNoteJson(updatedAt: version);

      // WHEN
      final note = NoteModel.fromJson(json);

      // THEN
      expect(
        note.version,
        version,
        reason: 'Microseconds must survive; web DateTime only keeps milliseconds',
      );
    });

    test('is null when the server does not send updated_at', () {
      // GIVEN
      final json = givenCategoryJson();

      // WHEN
      final category = CategoryModel.fromJson(json);

      // THEN
      expect(category.version, isNull, reason: 'An older server sends no version, so writes stay unconditional');
    });

    test('survives copyWith', () {
      // GIVEN
      final homework = HomeworkModel.fromJson({
        ...givenHomeworkJson(),
        'updated_at': version,
      });

      // WHEN
      final copy = homework.copyWith(title: 'Renamed');

      // THEN
      expect(copy.version, version);
    });
  });
}
