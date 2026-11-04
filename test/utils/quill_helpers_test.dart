import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

void main() {
  group('tryParseNotesDocument', () {
    test('parses already-terminated content unchanged', () {
      final doc = tryParseNotesDocument({
        'ops': [
          {'insert': 'Hello\n'}
        ]
      });

      expect(doc, isNotNull);
      expect(doc!.toPlainText(), 'Hello\n');
    });

    test('repairs content that does not end in a newline', () {
      // An un-terminated delta parses into a child-less document that crashes
      // flutter_quill on tap; the repair appends the required trailing newline.
      final doc = tryParseNotesDocument({
        'ops': [
          {'insert': 'Hello'}
        ]
      });

      expect(doc, isNotNull);
      final lastInsert = doc!.toDelta().toList().last.data as String;
      expect(lastInsert.endsWith('\n'), isTrue);
      expect(doc.toPlainText(), 'Hello\n');
    });

    test('returns null for empty ops so the caller shows a placeholder', () {
      expect(tryParseNotesDocument({'ops': <dynamic>[]}), isNull);
    });

    test('returns null when notes is null', () {
      expect(tryParseNotesDocument(null), isNull);
    });
  });

  group('notesDocumentFor', () {
    test('a note holding change ops is unrenderable, shown as a placeholder', () {
      // GIVEN
      final content = {
        'ops': [
          {'insert': 'Lecture 4\n'},
          {'retain': 3, 'attributes': {'bold': true}},
        ],
      };

      // WHEN
      final loaded = notesDocumentFor(content);

      // THEN
      expect(loaded.isRenderable, isFalse);
      expect(loaded.document.toPlainText(), contains('cannot be loaded'));
    });

    test('a valid note is renderable', () {
      // WHEN
      final loaded = notesDocumentFor({
        'ops': [
          {'insert': 'Hello\n'},
        ],
      });

      // THEN
      expect(loaded.isRenderable, isTrue);
      expect(loaded.document.toPlainText(), 'Hello\n');
    });

    test('a note with no content is an empty, renderable document', () {
      // WHEN
      final loaded = notesDocumentFor(null);

      // THEN
      expect(loaded.isRenderable, isTrue);
      expect(loaded.document.toPlainText(), '\n');
    });

    test('a note whose content was cleared stays editable', () {
      // WHEN
      final loaded = notesDocumentFor({});

      // THEN
      expect(loaded.isRenderable, isTrue);
      expect(loaded.document.toPlainText(), '\n');
    });
  });

  group('editorDeltaFor', () {
    test('matches the editor for stored ops Quill regroups on load', () {
      // GIVEN
      final stored = [
        {'insert': 'Come ready to discuss:\n'},
        {'insert': 'Final project milestones'},
        {'insert': '\n'},
      ];
      final editorDelta = Document.fromJson(stored).toDelta();

      // WHEN
      final savedDelta = editorDeltaFor({'ops': stored});

      // THEN
      expect(jsonEncode(editorDelta.toJson()), isNot(jsonEncode(stored)));
      expect(savedDelta, editorDelta);
    });

    test('matches the editor when storage reorders attribute keys', () {
      // GIVEN
      final editorDelta = Document.fromJson([
        {'insert': 'Exam', 'attributes': {'italic': true, 'bold': true}},
        {'insert': '\n'},
      ]).toDelta();
      final storedByMySql = [
        {'insert': 'Exam', 'attributes': {'bold': true, 'italic': true}},
        {'insert': '\n'},
      ];

      // WHEN
      final savedDelta = editorDeltaFor({'ops': storedByMySql});

      // THEN
      expect(jsonEncode(editorDelta.toJson()), isNot(jsonEncode(storedByMySql)));
      expect(savedDelta, editorDelta);
    });

    test('a note with no content matches an empty editor', () {
      // WHEN
      final savedDelta = editorDeltaFor(null);

      // THEN
      expect(savedDelta, Document().toDelta());
    });

    test('differs from the editor when the content was edited', () {
      // GIVEN
      final editorDelta = Document.fromJson([
        {'insert': 'Exam', 'attributes': {'bold': true}},
        {'insert': '\n'},
      ]).toDelta();

      // WHEN
      final savedDelta = editorDeltaFor({
        'ops': [
          {'insert': 'Exam\n'},
        ],
      });

      // THEN
      expect(savedDelta, isNot(editorDelta));
    });
  });
}
