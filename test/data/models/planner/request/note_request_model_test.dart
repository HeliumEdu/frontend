import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';

void main() {
  group('NoteRequestModel', () {
    group('toJson', () {
      test('links a note to a class and clears the other link types', () {
        // GIVEN
        final request = NoteRequestModel(courseId: 3);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['courses'], [3]);
        expect(json['homework'], isEmpty);
        expect(json['events'], isEmpty);
        expect(json['resources'], isEmpty);
      });

      test('relinking elsewhere clears an earlier class link', () {
        // GIVEN
        final request = NoteRequestModel(resourceId: 7);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['resources'], [7]);
        expect(json['courses'], isEmpty,
            reason: 'a class link left behind would make the server reject the relink');
      });

      test('unlinking clears the class link', () {
        // GIVEN
        final request = NoteRequestModel(clearLinks: true);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['courses'], isEmpty);
      });

      test('a content-only update leaves links alone', () {
        // GIVEN
        final request = NoteRequestModel(content: {'ops': []});

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json.containsKey('courses'), isFalse);
      });
    });
  });
}
