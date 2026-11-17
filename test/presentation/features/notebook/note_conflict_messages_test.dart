import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/features/notebook/note_conflict_messages.dart';

void main() {
  group('changedSinceDraftMessage', () {
    test(
      'a recovered draft says how long before it the other device changed the note',
      () {
        // GIVEN
        final latest = NoteModel(
          id: 1,
          title: 'Lecture 4',
          updatedAt: DateTime.utc(2026, 11, 17, 9, 55),
        );

        // WHEN
        final message = changedSinceDraftMessage(
          latest,
          DateTime.utc(2026, 11, 17, 10),
        );

        // THEN
        expect(message.title, 'Recover Your Changes?');
        expect(message.discardLabel, 'Discard');
        expect(message.saveLabel, 'Recover');
        expect(
          message.body,
          startsWith('This note was changed on another device '),
        );
        expect(
          message.body,
          contains(
            ' before your recovered changes. Recover your changes anyway',
          ),
        );
      },
    );

    test(
      'with no draft time or server version it omits when the change happened',
      () {
        // GIVEN
        final latest = NoteModel(
          id: 1,
          title: 'Lecture 4',
          updatedAt: DateTime.utc(2026, 11, 17, 9, 55),
        );

        // WHEN
        final message = changedSinceDraftMessage(latest, null);

        // THEN
        expect(
          message.body,
          'This note was changed on another device. Recover your changes anyway, replacing that version?',
        );
      },
    );
  });
}
