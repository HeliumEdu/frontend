import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/unconfirmed_note_saves.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';

List<Map<String, dynamic>> _ops(String text) => [
  {'insert': '$text\n'},
];

NoteModel _serverNote(String title, String text) => NoteModel(
  id: 1,
  title: title,
  updatedAt: DateTime.utc(2026, 11, 17),
  content: {'ops': _ops(text)},
);

void main() {
  group('UnconfirmedNoteSaves', () {
    test(
      'a server version matching a remembered save is this device\'s own write',
      () {
        // GIVEN
        final saves = UnconfirmedNoteSaves()
          ..remember('Lecture 4', _ops('draft'));

        // WHEN
        final isOwn = saves.isOwnWrite(_serverNote('Lecture 4', 'draft'));

        // THEN
        expect(isOwn, isTrue);
      },
    );

    test(
      'a server version with a different title is not this device\'s write',
      () {
        // GIVEN
        final saves = UnconfirmedNoteSaves()
          ..remember('Lecture 4', _ops('draft'));

        // WHEN
        final isOwn = saves.isOwnWrite(_serverNote('Lecture 5', 'draft'));

        // THEN
        expect(isOwn, isFalse);
      },
    );

    test('a server version without content is never this device\'s write', () {
      // GIVEN
      final saves = UnconfirmedNoteSaves()
        ..remember('Lecture 4', _ops('draft'));
      final latest = NoteModel(
        id: 1,
        title: 'Lecture 4',
        updatedAt: DateTime.utc(2026, 11, 17),
      );

      // WHEN
      final isOwn = saves.isOwnWrite(latest);

      // THEN
      expect(isOwn, isFalse);
    });

    test('past the cap it keeps the oldest save and drops the next oldest', () {
      // GIVEN
      final saves = UnconfirmedNoteSaves();
      for (var i = 1; i <= 6; i++) {
        saves.remember('Lecture 4', _ops('edit $i'));
      }

      // WHEN
      final keepsOldest = saves.isOwnWrite(_serverNote('Lecture 4', 'edit 1'));
      final keepsSecond = saves.isOwnWrite(_serverNote('Lecture 4', 'edit 2'));
      final keepsNewest = saves.isOwnWrite(_serverNote('Lecture 4', 'edit 6'));

      // THEN
      expect(
        keepsOldest,
        isTrue,
        reason: 'the oldest is the save in flight when the connection dropped',
      );
      expect(keepsSecond, isFalse);
      expect(keepsNewest, isTrue);
    });

    test('clearing forgets every remembered save', () {
      // GIVEN
      final saves = UnconfirmedNoteSaves()
        ..remember('Lecture 4', _ops('draft'));

      // WHEN
      saves.clear();

      // THEN
      expect(saves.isOwnWrite(_serverNote('Lecture 4', 'draft')), isFalse);
    });
  });
}
