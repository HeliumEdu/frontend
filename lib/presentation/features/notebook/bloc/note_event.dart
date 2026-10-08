import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class NoteEvent extends BaseEvent {
  NoteEvent({required super.origin});
}

/// Clears all note state. Dispatched on logout so per-user data does not
/// carry into the next session.
class ResetNotesEvent extends NoteEvent {
  ResetNotesEvent() : super(origin: EventOrigin.bloc);
}

class FetchNotesEvent extends NoteEvent {
  final String? search;
  final String? linkedEntityType;
  final bool shownOnCalendar;
  final bool forceRefresh;

  FetchNotesEvent({
    required super.origin,
    this.search,
    this.linkedEntityType,
    this.shownOnCalendar = false,
    this.forceRefresh = false,
  });
}

class FetchNoteScreenDataEvent extends NoteEvent {
  final int? noteId;
  final int? linkHomeworkId;
  final int? linkEventId;
  final int? linkResourceId;

  FetchNoteScreenDataEvent({
    required super.origin,
    this.noteId,
    this.linkHomeworkId,
    this.linkEventId,
    this.linkResourceId,
  });
}

class FetchLinkableEntitiesEvent extends NoteEvent {
  final int? currentNoteId;

  FetchLinkableEntitiesEvent({
    required super.origin,
    this.currentNoteId,
  });
}

class CreateNoteEvent extends NoteEvent {
  final NoteRequestModel request;

  CreateNoteEvent({
    required super.origin,
    required this.request,
  });
}

class UpdateNoteEvent extends NoteEvent {
  final int noteId;
  final NoteRequestModel request;

  /// The note's version as last read; when set, a stale save emits
  /// [NoteConflict] instead of overwriting.
  final String? version;

  /// When set, a stale save keeps the request's content as a standalone note
  /// with this title, emitting [NoteSavedAsCopy], instead of [NoteConflict].
  /// For forms that save a linked note and may close before it finishes.
  final String? copyTitleOnConflict;

  UpdateNoteEvent({
    required super.origin,
    required this.noteId,
    required this.request,
    this.version,
    this.copyTitleOnConflict,
  });
}

class RefreshNoteEvent extends NoteEvent {
  final int noteId;

  RefreshNoteEvent({
    required super.origin,
    required this.noteId,
  });
}

class DeleteNoteEvent extends NoteEvent {
  final int noteId;

  DeleteNoteEvent({
    required super.origin,
    required this.noteId,
  });
}
