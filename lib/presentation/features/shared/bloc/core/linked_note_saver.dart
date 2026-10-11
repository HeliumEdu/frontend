import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';

class LinkedNoteSave {
  final int? noteId;
  final NoteModel? note;
  final bool savedAsCopy;

  const LinkedNoteSave({
    required this.noteId,
    this.note,
    this.savedAsCopy = false,
  });
}

class FormSave<T> {
  final T? entity;
  final LinkedNoteSave? note;
  final ConflictException? entityConflict;

  const FormSave({this.entity, this.note, this.entityConflict});
}

/// Saves the note linked to a homework, event or resource from that entity's
/// form.
class LinkedNoteSaver {
  final NoteRepository noteRepository;

  const LinkedNoteSaver(this.noteRepository);

  /// Saves an entity and its linked note in parallel. A stale entity save is
  /// reported as [FormSave.entityConflict] once both finish, so the note's
  /// outcome is known; any other failure is rethrown.
  static Future<FormSave<T>> saveWithEntity<T>(
    Future<T> entitySave,
    Future<LinkedNoteSave> noteSave,
  ) async {
    T? entity;
    LinkedNoteSave? note;
    (Object, StackTrace)? entityFailure;
    (Object, StackTrace)? noteFailure;
    await Future.wait([
      entitySave.then<void>(
        (value) => entity = value,
        onError: (Object e, StackTrace s) {
          entityFailure = (e, s);
        },
      ),
      noteSave.then<void>(
        (value) => note = value,
        onError: (Object e, StackTrace s) {
          noteFailure = (e, s);
        },
      ),
    ]);

    if (entityFailure?.$1 case final ConflictException conflict) {
      return FormSave(entityConflict: conflict, note: note);
    }
    for (final failure in [entityFailure, noteFailure]) {
      if (failure != null) Error.throwWithStackTrace(failure.$1, failure.$2);
    }
    return FormSave(entity: entity, note: note);
  }

  /// An untouched note isn't saved. If the note changed elsewhere, this
  /// device's text is kept as a separate note, so neither version is lost.
  Future<LinkedNoteSave> save({
    required int? linkedNoteId,
    required String? linkedNoteVersion,
    required bool noteEdited,
    required Map<String, dynamic>? noteContent,
    required String? entityTitle,
    int? homeworkId,
    int? eventId,
    int? resourceId,
  }) async {
    if (linkedNoteId == null) {
      if (noteContent == null) return const LinkedNoteSave(noteId: null);
      final note = await noteRepository.createNote(
        request: NoteRequestModel(
          content: noteContent,
          homeworkId: homeworkId,
          eventId: eventId,
          resourceId: resourceId,
        ),
      );
      return LinkedNoteSave(noteId: note.id, note: note);
    }
    if (!noteEdited) return LinkedNoteSave(noteId: linkedNoteId);

    try {
      // Empty content triggers note deletion on backend
      final note = await noteRepository.updateNote(
        noteId: linkedNoteId,
        request: NoteRequestModel(content: noteContent ?? <String, dynamic>{}),
        version: linkedNoteVersion,
      );
      return LinkedNoteSave(noteId: note?.id, note: note);
    } on ConflictException catch (e) {
      final latest = NoteModel.fromJson(e.latest);
      if (noteContent == null) {
        return LinkedNoteSave(noteId: linkedNoteId, note: latest);
      }
      await noteRepository.createNote(
        request: NoteRequestModel.conflictCopy(
          title: entityTitle ?? '',
          content: noteContent,
        ),
      );
      return LinkedNoteSave(
        noteId: linkedNoteId,
        note: latest,
        savedAsCopy: true,
      );
    }
  }
}
