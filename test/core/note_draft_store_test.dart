import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/note_draft_store.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_services.dart';

void main() {
  late Map<String, String> stored;
  late NoteDraftStore store;

  setUp(() {
    stored = {};
    final sharedStorage = MockSharedPreferencesWithCache();
    when(() => sharedStorage.getString(any())).thenAnswer(
      (invocation) => stored[invocation.positionalArguments.first as String],
    );
    when(() => sharedStorage.setString(any(), any())).thenAnswer((invocation) {
      stored[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1] as String;
      return Future.value();
    });
    when(() => sharedStorage.remove(any())).thenAnswer((invocation) {
      stored.remove(invocation.positionalArguments.first);
      return Future.value();
    });
    store = NoteDraftStore.forTesting(
      prefService: PrefService.forTesting(
        secureStorage: MockFlutterSecureStorage(),
        sharedStorage: sharedStorage,
      ),
    );
  });

  tearDown(PrefService.resetForTesting);

  NoteDraft givenDraft(String title, {int? homeworkId}) => (
    title: title,
    ops: [
      {'insert': '$title body\n'},
    ],
    baseVersion: '2026-11-03T12:00:00.123456Z',
    homeworkId: homeworkId,
    eventId: null,
    resourceId: null,
  );

  void givenStoredDraft(int noteId, {required DateTime savedAt}) {
    final drafts = stored['note_drafts'] == null
        ? <String, dynamic>{}
        : jsonDecode(stored['note_drafts']!) as Map<String, dynamic>;
    drafts['$noteId'] = {
      'title': 'Old',
      'ops': [
        {'insert': 'Old body\n'},
      ],
      'base_version': '2026-09-01T12:00:00.000000Z',
      'saved_at': savedAt.toUtc().toIso8601String(),
    };
    stored['note_drafts'] = jsonEncode(drafts);
  }

  test('a saved draft reads back for its note only', () {
    // WHEN
    store.save(NoteDraftStore.keyForNote(7), givenDraft('Lecture 4'));

    // THEN
    final draft = store.draftFor(NoteDraftStore.keyForNote(7));
    expect(draft?.title, 'Lecture 4');
    expect(draft?.ops, givenDraft('Lecture 4').ops);
    expect(draft?.baseVersion, givenDraft('Lecture 4').baseVersion);
    expect(store.draftFor(NoteDraftStore.keyForNote(8)), isNull);
  });

  test('a draft reports when it was last saved', () {
    // GIVEN
    final savedAt = DateTime.utc(2026, 11, 3, 15, 10);
    givenStoredDraft(7, savedAt: savedAt);

    // WHEN
    final reported = store.savedAtFor(NoteDraftStore.keyForNote(7));

    // THEN
    expect(reported, savedAt);
    expect(store.savedAtFor(NoteDraftStore.keyForNote(8)), isNull);
  });

  test('clearing a draft leaves the other notes\' drafts', () {
    // GIVEN
    store.save(NoteDraftStore.keyForNote(7), givenDraft('Lecture 4'));
    store.save(NoteDraftStore.keyForNote(8), givenDraft('Lab'));

    // WHEN
    store.clear(NoteDraftStore.keyForNote(7));

    // THEN
    expect(store.draftFor(NoteDraftStore.keyForNote(7)), isNull);
    expect(store.draftFor(NoteDraftStore.keyForNote(8))?.title, 'Lab');
  });

  test('clearing the last draft removes the stored drafts', () {
    // GIVEN
    store.save(NoteDraftStore.keyForNote(7), givenDraft('Lecture 4'));

    // WHEN
    store.clear(NoteDraftStore.keyForNote(7));

    // THEN
    expect(stored.containsKey('note_drafts'), isFalse);
  });

  test('drafts older than 90 days are dropped on the next save', () {
    // GIVEN
    givenStoredDraft(
      1,
      savedAt: DateTime.now().subtract(const Duration(days: 91)),
    );
    givenStoredDraft(
      2,
      savedAt: DateTime.now().subtract(const Duration(days: 89)),
    );

    // WHEN
    store.save(NoteDraftStore.keyForNote(7), givenDraft('Lecture 4'));

    // THEN
    expect(store.draftFor(NoteDraftStore.keyForNote(1)), isNull);
    expect(store.draftFor(NoteDraftStore.keyForNote(2)), isNotNull);
    expect(store.draftFor(NoteDraftStore.keyForNote(7)), isNotNull);
  });

  test('unreadable stored drafts read as none', () {
    // GIVEN
    stored['note_drafts'] = '{not json';

    // WHEN
    final draft = store.draftFor(NoteDraftStore.keyForNote(7));

    // THEN
    expect(draft, isNull);
  });

  group('new notes', () {
    test('the note not yet created keeps its link without a version', () {
      // GIVEN
      const draft = (
        title: 'Lecture 5',
        ops: <dynamic>[],
        baseVersion: null,
        homeworkId: 12,
        eventId: null,
        resourceId: null,
      );

      // WHEN
      store.save(NoteDraftStore.newNoteKey, draft);

      // THEN
      final recovered = store.draftFor(NoteDraftStore.newNoteKey);
      expect(recovered?.title, 'Lecture 5');
      expect(recovered?.baseVersion, isNull);
      expect(recovered?.homeworkId, 12);
    });
  });
}
