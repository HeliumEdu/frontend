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
  String? _conflictingNoteVersion;

  void loadLinkedNote(NoteModel? note) {
    linkedNoteId = note?.id;
    linkedNoteVersion = note?.version;
    notesEdited = false;
    _conflictingNoteVersion = null;
    notesController.dispose();
    notesController = heliumQuillController(
      document: note?.content != null
          ? tryParseNotesDocument(note!.content) ??
              buildUnrenderableNotePlaceholder()
          : null,
    );
  }

  void applyLinkedNoteSave(LinkedNoteSave? save) {
    _conflictingNoteVersion = null;
    if (save == null) return;

    if (save.isConflict) {
      _conflictingNoteVersion = save.note?.version;
      return;
    }
    linkedNoteId = save.noteId;
    if (save.note != null || save.noteId == null) {
      linkedNoteVersion = save.note?.version;
    }
    notesEdited = false;
  }

  String? linkedNoteVersionToSend({required bool overwrite}) => overwrite
      ? _conflictingNoteVersion ?? linkedNoteVersion
      : linkedNoteVersion;
}
