import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';

abstract class NoteRepository {
  Future<List<NoteModel>> getNotes({
    String? search,
    String? linkedEntityType,
    int? homeworkId,
    int? eventId,
    int? resourceId,
    DateTime? updatedAtGte,
    bool includeContent = false,
    bool shownOnCalendar = false,
    bool forceRefresh = false,
  });

  Future<NoteModel> getNote({
    required int id,
    bool forceRefresh = false,
  });

  Future<NoteModel> createNote({required NoteRequestModel request});

  /// Updates a note. Returns the updated note, or null if the note was deleted
  /// (when content is cleared on a note with linked entities).
  Future<NoteModel?> updateNote({
    required int noteId,
    required NoteRequestModel request,
  });

  Future<void> deleteNote({required int noteId});
}
