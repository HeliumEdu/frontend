import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

mixin LinkedNoteFormFields on BasicFormController {
  QuillController notesController = heliumQuillController();
  int? linkedNoteId;
  String? linkedNoteVersion;
  bool notesEdited = false;
  NoteModel? _conflictingNote;
  StreamSubscription<DocChange>? _noteEdits;

  /// The note to open in the Notebook: the newer one when a save lost to it.
  int? get noteIdToOpen => _conflictingNote?.id ?? linkedNoteId;

  /// Whether overwriting the newer note with this form's would delete it,
  /// leaving it with no content and no title.
  bool get overwriteDeletesNote =>
      _conflictingNote != null &&
      _conflictingNote!.title.trim().isEmpty &&
      buildNotesDelta(notesController) == null;

  void loadLinkedNote(NoteModel? note) {
    linkedNoteId = note?.id;
    linkedNoteVersion = note?.version;
    notesEdited = false;
    _conflictingNote = null;
    notesController.dispose();
    notesController = heliumQuillController(
      document: note?.content != null
          ? tryParseNotesDocument(note!.content) ??
              buildUnrenderableNotePlaceholder()
          : null,
    );
  }

  void listenForNoteEdits() {
    _noteEdits?.cancel();
    _noteEdits = notesController.document.changes.listen(_onNoteChange);
  }

  void disposeLinkedNote() {
    _noteEdits?.cancel();
    notesController.dispose();
  }

  void applyLinkedNoteSave(LinkedNoteSave? save) {
    _conflictingNote = null;
    if (save == null || save.failure != null) return;

    if (save.isConflict) {
      _conflictingNote = save.note;
      return;
    }
    linkedNoteId = save.noteId;
    if (save.note != null || save.noteId == null) {
      linkedNoteVersion = save.note?.version;
    }
    notesEdited = false;
  }

  LinkedNoteEdit linkedNoteEdit({required bool overwrite}) => LinkedNoteEdit(
    noteId: overwrite ? noteIdToOpen : linkedNoteId,
    version: overwrite
        ? _conflictingNote?.version ?? linkedNoteVersion
        : linkedNoteVersion,
    edited: notesEdited,
    content: buildNotesDelta(notesController),
  );

  void _onNoteChange(DocChange change) {
    if (!isNoteEdited(change)) return;
    markChanged();
    notesEdited = true;
  }
}
