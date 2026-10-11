import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';

typedef _Settled<T> = ({T? value, (Object, StackTrace)? failure});

class LinkedNoteSave {
  final int? noteId;
  final NoteModel? note;
  final bool isConflict;

  const LinkedNoteSave({
    required this.noteId,
    this.note,
    this.isConflict = false,
  });
}

class FormSave<T> {
  final T? entity;
  final LinkedNoteSave? note;
  final ConflictException? entityConflict;

  const FormSave({this.entity, this.note, this.entityConflict});
}

class LinkedNoteSaver {
  final NoteRepository noteRepository;

  const LinkedNoteSaver(this.noteRepository);

  static Future<FormSave<T>> saveWithEntity<T>(
    Future<T> entitySave,
    Future<LinkedNoteSave> noteSave,
  ) async {
    final (entity, note) = await (_settle(entitySave), _settle(noteSave)).wait;

    if (entity.failure?.$1 case final ConflictException conflict) {
      return FormSave(entityConflict: conflict, note: note.value);
    }
    for (final failure in [entity.failure, note.failure]) {
      if (failure != null) Error.throwWithStackTrace(failure.$1, failure.$2);
    }
    return FormSave(entity: entity.value, note: note.value);
  }

  static Future<_Settled<T>> _settle<T>(Future<T> future) async {
    try {
      return (value: await future, failure: null);
    } catch (e, s) {
      return (value: null, failure: (e, s));
    }
  }

  Future<LinkedNoteSave> save({
    required int? linkedNoteId,
    required String? linkedNoteVersion,
    required bool noteEdited,
    required Map<String, dynamic>? noteContent,
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
      return LinkedNoteSave(
        noteId: linkedNoteId,
        note: NoteModel.fromJson(e.latest),
        isConflict: true,
      );
    }
  }
}
