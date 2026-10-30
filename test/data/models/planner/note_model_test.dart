import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';

import '../../../helpers/note_helper.dart';
import '../../../mocks/mock_models.dart';

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

  group('NoteModel.courseId', () {
    test('parses the linked assignment\'s class', () {
      // GIVEN
      final json = {
        ...givenNoteJson(homework: [5]),
        'course_id': 3,
      };

      // WHEN
      final note = NoteModel.fromJson(json);

      // THEN
      expect(note.courseId, 3);
      expect(note.copyWith(title: 'Renamed').courseId, 3);
    });
  });

  group('NoteModel.matchesCourseFilter', () {
    final resourcesById = {
      7: MockModels.createResource(id: 7, courses: [3, 4]),
      8: MockModels.createResource(id: 8, courses: []),
    };

    NoteModel givenNote(Map<String, dynamic> changes) =>
        NoteModel.fromJson({...givenNoteJson(), ...changes});

    test('narrows an assignment\'s note by its class', () {
      // GIVEN
      final note = givenNote({
        'homework': [5],
        'linked_entity_type': 'homework',
        'course_id': 3,
      });

      // WHEN/THEN
      expect(note.matchesCourseFilter({3}, resourcesById), isTrue);
      expect(note.matchesCourseFilter({9}, resourcesById), isFalse);
    });

    test('narrows a resource\'s note by any of the resource\'s classes', () {
      // GIVEN
      final note = givenNote({
        'resources': [7],
        'linked_entity_type': 'resource',
      });

      // WHEN/THEN
      expect(note.matchesCourseFilter({4}, resourcesById), isTrue);
      expect(note.matchesCourseFilter({9}, resourcesById), isFalse);
    });

    test('keeps notes that aren\'t tied to a class', () {
      // GIVEN
      final standalone = givenNote({});
      final event = givenNote({
        'events': [2],
        'linked_entity_type': 'event',
      });
      final classlessResource = givenNote({
        'resources': [8],
        'linked_entity_type': 'resource',
      });
      final unknownAssignmentClass = givenNote({
        'homework': [5],
        'linked_entity_type': 'homework',
      });

      // WHEN/THEN
      for (final note in [
        standalone,
        event,
        classlessResource,
        unknownAssignmentClass,
      ]) {
        expect(
          note.matchesCourseFilter({9}, resourcesById),
          isTrue,
          reason:
              'like the Planner, a class filter only narrows items tied to a class',
        );
      }
    });
  });
}
