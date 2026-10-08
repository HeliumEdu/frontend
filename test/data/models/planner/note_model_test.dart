import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';

import '../../../helpers/note_helper.dart';

void main() {
  const version = '2026-10-07T12:00:00.123456Z';

  group('NoteModel.version', () {
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

    test('survives copyWith', () {
      // GIVEN
      final note = NoteModel.fromJson(givenNoteJson(updatedAt: version));

      // WHEN
      final copy = note.copyWith(title: 'Renamed');

      // THEN
      expect(copy.version, version);
    });
  });
}
