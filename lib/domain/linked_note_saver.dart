import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';

typedef _Settled<T> = ({T? value, (Object, StackTrace)? failure});

class LinkedNoteEdit {
  final int? noteId;
  final String? version;
  final bool edited;
  final Map<String, dynamic>? content;

  const LinkedNoteEdit({
    this.noteId,
    this.version,
    this.edited = true,
    this.content,
  });
}

class LinkedNoteSave {
  final int? noteId;
  final NoteModel? note;
  final bool isConflict;

  /// The note was deleted on another device, so it was saved as a new one.
  final bool isRecreated;

  /// The note that was cleared, so Helium deleted it.
  final int? deletedNoteId;

  /// Why the note didn't save, when its item did.
  final HeliumException? failure;

  const LinkedNoteSave({
    required this.noteId,
    this.note,
    this.isConflict = false,
    this.isRecreated = false,
    this.deletedNoteId,
    this.failure,
  });

  bool get isSaved => !isConflict && failure == null;

  bool get isDeleted => deletedNoteId != null;
}

class FormSave<T> {
  final T? entity;
  final LinkedNoteSave? note;
  final ConflictException? entityConflict;
  final HeliumException? entityFailure;

  const FormSave({
    this.entity,
    this.note,
    this.entityConflict,
    this.entityFailure,
  });
}

class LinkedNoteSaver {
  final NoteRepository noteRepository;

  const LinkedNoteSaver(this.noteRepository);

  /// Saves an item and its linked note together. When one fails and the other
  /// saves, the failure comes back beside the saved result rather than
  /// replacing it.
  Future<FormSave<T>> saveWithEntity<T>(
    Future<T> entitySave,
    LinkedNoteEdit noteEdit, {
    int? homeworkId,
    int? eventId,
    int? resourceId,
  }) async {
    final noteSave = save(
      noteEdit,
      homeworkId: homeworkId,
      eventId: eventId,
      resourceId: resourceId,
    );
    final (entity, note) = await (_settle(entitySave), _settle(noteSave)).wait;

    final noteFailure = note.failure;
    if (noteFailure != null && noteFailure.$1 is! HeliumException) {
      Error.throwWithStackTrace(noteFailure.$1, noteFailure.$2);
    }
    final linkedNote =
        note.value ??
        LinkedNoteSave(
          noteId: noteEdit.noteId,
          failure: noteFailure!.$1 as HeliumException,
        );

    if (entity.failure?.$1 case final ConflictException conflict) {
      return FormSave(entityConflict: conflict, note: linkedNote);
    }
    if (entity.failure?.$1 case final HeliumException failure) {
      return FormSave(entityFailure: failure, note: linkedNote);
    }
    if (entity.failure case (final Object error, final StackTrace stack)) {
      Error.throwWithStackTrace(error, stack);
    }
    return FormSave(entity: entity.value, note: linkedNote);
  }

  /// Saves the note of an item just created; the item already exists, so a
  /// failure comes back as [LinkedNoteSave.failure].
  Future<LinkedNoteSave> saveForNewEntity(
    Map<String, dynamic>? content, {
    int? homeworkId,
    int? eventId,
    int? resourceId,
  }) async {
    try {
      return await _create(
        content,
        homeworkId: homeworkId,
        eventId: eventId,
        resourceId: resourceId,
      );
    } on HeliumException catch (e) {
      return LinkedNoteSave(noteId: null, failure: e);
    }
  }

  Future<LinkedNoteSave> save(
    LinkedNoteEdit noteEdit, {
    int? homeworkId,
    int? eventId,
    int? resourceId,
  }) async {
    final linkedNoteId = noteEdit.noteId;
    if (linkedNoteId == null) {
      return _create(
        noteEdit.content,
        homeworkId: homeworkId,
        eventId: eventId,
        resourceId: resourceId,
      );
    }
    if (!noteEdit.edited) return LinkedNoteSave(noteId: linkedNoteId);

    try {
      // A linked note left with no content and no title is deleted
      final note = await noteRepository.updateNote(
        noteId: linkedNoteId,
        request: NoteRequestModel(
          content: noteEdit.content ?? <String, dynamic>{},
        ),
        version: noteEdit.version,
      );
      if (note == null) {
        return LinkedNoteSave(noteId: null, deletedNoteId: linkedNoteId);
      }
      return LinkedNoteSave(noteId: note.id, note: note);
    } on ConflictException catch (e) {
      return LinkedNoteSave(
        noteId: linkedNoteId,
        note: NoteModel.fromJson(e.latest),
        isConflict: true,
      );
    } on NotFoundException {
      return _create(
        noteEdit.content,
        homeworkId: homeworkId,
        eventId: eventId,
        resourceId: resourceId,
        isRecreated: true,
      );
    }
  }

  /// A new note for the item, or, when another device already gave the item a
  /// note, a conflict with that one.
  Future<LinkedNoteSave> _create(
    Map<String, dynamic>? content, {
    int? homeworkId,
    int? eventId,
    int? resourceId,
    bool isRecreated = false,
  }) async {
    if (content == null) return const LinkedNoteSave(noteId: null);
    try {
      final note = await noteRepository.createNote(
        request: NoteRequestModel(
          content: content,
          homeworkId: homeworkId,
          eventId: eventId,
          resourceId: resourceId,
        ),
      );
      return LinkedNoteSave(
        noteId: note.id,
        note: note,
        isRecreated: isRecreated,
      );
    } on ValidationException {
      final existing = (await noteRepository.getNotes(
        homeworkId: homeworkId,
        eventId: eventId,
        resourceId: resourceId,
        includeContent: true,
        forceRefresh: true,
      )).firstOrNull;
      if (existing == null) rethrow;
      return LinkedNoteSave(
        noteId: existing.id,
        note: existing,
        isConflict: true,
      );
    }
  }

  static Future<_Settled<T>> _settle<T>(Future<T> future) async {
    try {
      return (value: await future, failure: null);
    } catch (e, s) {
      return (value: null, failure: (e, s));
    }
  }
}
