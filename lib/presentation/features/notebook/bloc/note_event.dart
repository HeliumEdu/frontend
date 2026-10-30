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

class SearchNoteContentEvent extends NoteEvent {
  final String search;
  final bool shownOnCalendar;

  SearchNoteContentEvent({
    required super.origin,
    required this.search,
    this.shownOnCalendar = false,
  });
}

class FetchNotebookScreenDataEvent extends NoteEvent {
  final bool shownOnCalendar;
  final bool forceRefresh;

  FetchNotebookScreenDataEvent({
    required super.origin,
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

  final String? version;

  UpdateNoteEvent({
    required super.origin,
    required this.noteId,
    required this.request,
    this.version,
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
