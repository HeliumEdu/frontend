import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('allowsTypedText', () {
    QuillController bulletList({required int caret}) => QuillController(
      document: Document.fromJson([
        {'insert': 'First'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Second'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ]),
      selection: TextSelection.collapsed(offset: caret),
    );

    bool isIndented(QuillController controller) => controller.document
        .toDelta()
        .toList()
        .any((op) => op.attributes?['indent'] == 1);

    test('a tab typed at the start of a list item indents it instead', () async {
      // GIVEN
      final controller = bulletList(caret: 6);

      // WHEN
      final typed = allowsTypedText(controller, 6, 0, '\t');
      await pumpEventQueue();

      // THEN
      expect(typed, isFalse);
      expect(isIndented(controller), isTrue);
      expect(controller.document.toPlainText(), 'First\nSecond\n');
    });

    test('a tab typed inside a list item\'s text is typed', () async {
      // GIVEN
      final controller = bulletList(caret: 9);

      // WHEN
      final typed = allowsTypedText(controller, 9, 0, '\t');
      await pumpEventQueue();

      // THEN
      expect(typed, isTrue);
      expect(isIndented(controller), isFalse);
    });

    test('a tab typed in a plain paragraph is typed', () {
      // GIVEN
      final controller = QuillController(
        document: Document.fromJson([
          {'insert': 'Plain\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );

      // WHEN
      final typed = allowsTypedText(controller, 0, 0, '\t');

      // THEN
      expect(typed, isTrue);
    });

    test('a tab typed over a selection outside a list changes nothing', () async {
      // GIVEN
      final controller = QuillController(
        document: Document.fromJson([
          {'insert': 'Plain\n'},
        ]),
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );

      // WHEN
      final typed = allowsTypedText(controller, 0, 5, '\t');
      await pumpEventQueue();

      // THEN
      expect(typed, isFalse);
      expect(controller.document.toPlainText(), 'Plain\n');
    });

    test('other typed text goes in untouched', () {
      // GIVEN
      final controller = bulletList(caret: 6);

      // WHEN
      final typed = allowsTypedText(controller, 6, 0, 'a');

      // THEN
      expect(typed, isTrue);
    });
  });
}
