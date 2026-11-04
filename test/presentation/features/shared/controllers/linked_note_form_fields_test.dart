import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/features/resources/controllers/resource_form_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ResourceFormController givenFormEditingNote(Map<String, dynamic> content) {
    final form = ResourceFormController()
      ..loadLinkedNote(
        NoteModel(
          id: 186415,
          title: 'Lecture 4',
          updatedAt: DateTime.utc(2026, 10, 7),
          content: content,
        ),
      )
      ..listenForNoteEdits();
    addTearDown(form.disposeLinkedNote);
    return form;
  }

  Future<void> typeIntoNote(ResourceFormController form) async {
    form.notesController.replaceText(
      0,
      0,
      'typed ',
      const TextSelection.collapsed(offset: 6),
    );
    await pumpEventQueue();
  }

  group('a linked note whose stored content cannot be rendered', () {
    const unrenderable = {
      'ops': [
        {'insert': 'Lecture 4\n'},
        {'retain': 3},
      ],
    };

    test('is read-only', () {
      // WHEN
      final form = givenFormEditingNote(unrenderable);

      // THEN
      expect(form.notesController.readOnly, isTrue);
    });

    test('is never saved over the stored content', () async {
      // GIVEN
      final form = givenFormEditingNote(unrenderable);

      // WHEN
      await typeIntoNote(form);

      // THEN
      expect(form.linkedNoteEdit(overwrite: false).edited, isFalse);
      expect(form.notesEdited, isFalse);
    });
  });

  test('a linked note that renders stays editable', () async {
    // GIVEN
    final form = givenFormEditingNote(const {
      'ops': [
        {'insert': 'Lab\n'},
      ],
    });

    // WHEN
    await typeIntoNote(form);

    // THEN
    expect(form.notesController.readOnly, isFalse);
    expect(form.notesEdited, isTrue);
  });
}
