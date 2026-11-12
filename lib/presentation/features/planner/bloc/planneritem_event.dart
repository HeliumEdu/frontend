import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class PlannerItemEvent extends BaseEvent {
  PlannerItemEvent({required super.origin});
}

/// Clears all planner item state. Dispatched on logout so per-user data does
/// not carry into the next session.
class ResetPlannerItemsEvent extends PlannerItemEvent {
  ResetPlannerItemsEvent() : super(origin: EventOrigin.bloc);
}

class FetchPlannerItemScreenDataEvent extends PlannerItemEvent {
  final int? eventId;
  final int? homeworkId;
  final bool forceRefresh;

  FetchPlannerItemScreenDataEvent({
    required super.origin,
    this.eventId,
    this.homeworkId,
    this.forceRefresh = false,
  });
}

class CreateEventEvent extends PlannerItemEvent {
  final EventRequestModel request;
  final bool advanceNavOnSuccess;
  final Map<String, dynamic>? noteContent;
  final bool redirectToNotebook;

  CreateEventEvent({
    required super.origin,
    required this.request,
    this.advanceNavOnSuccess = true,
    this.noteContent,
    this.redirectToNotebook = false,
  });
}

class CloneEventEvent extends PlannerItemEvent {
  final int eventId;

  final DateTime? occurrenceStart;

  CloneEventEvent({
    required super.origin,
    required this.eventId,
    this.occurrenceStart,
  });
}

class UpdateEventEvent extends PlannerItemEvent {
  final int id;
  final EventRequestModel request;
  final bool advanceNavOnSuccess;
  final LinkedNoteEdit linkedNote;
  final bool redirectToNotebook;
  final String? version;

  final DateTime? occurrenceStart;
  final bool onlyThisOccurrence;

  UpdateEventEvent({
    required super.origin,
    required this.id,
    required this.request,
    this.advanceNavOnSuccess = false,
    this.linkedNote = const LinkedNoteEdit(),
    this.redirectToNotebook = false,
    this.version,
    this.occurrenceStart,
    this.onlyThisOccurrence = false,
  });
}

class DeleteEventEvent extends PlannerItemEvent {
  final int id;

  final DateTime? occurrenceStart;

  DeleteEventEvent({
    required super.origin,
    required this.id,
    this.occurrenceStart,
  });
}

class DeleteAllEventsEvent extends PlannerItemEvent {
  DeleteAllEventsEvent({required super.origin});
}

class CreateHomeworkEvent extends PlannerItemEvent {
  final int courseGroupId;
  final int courseId;
  final HomeworkRequestModel request;
  final bool advanceNavOnSuccess;
  final Map<String, dynamic>? noteContent;
  final bool redirectToNotebook;

  CreateHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
    this.advanceNavOnSuccess = true,
    this.noteContent,
    this.redirectToNotebook = false,
  });
}

class CloneHomeworkEvent extends PlannerItemEvent {
  final int courseGroupId;
  final int courseId;
  final int homeworkId;

  final DateTime? occurrenceStart;

  CloneHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.homeworkId,
    this.occurrenceStart,
  });
}

class UpdateHomeworkEvent extends PlannerItemEvent {
  final int courseGroupId;
  final int courseId;
  final int homeworkId;
  final HomeworkRequestModel request;
  final bool advanceNavOnSuccess;
  final LinkedNoteEdit linkedNote;
  final bool redirectToNotebook;
  final String? version;

  final HomeworkModel? previousHomework;

  final DateTime? occurrenceStart;
  final bool onlyThisOccurrence;

  UpdateHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.homeworkId,
    required this.request,
    this.advanceNavOnSuccess = false,
    this.linkedNote = const LinkedNoteEdit(),
    this.redirectToNotebook = false,
    this.version,
    this.previousHomework,
    this.occurrenceStart,
    this.onlyThisOccurrence = false,
  });
}

class DeleteHomeworkEvent extends PlannerItemEvent {
  final int courseGroupId;
  final int courseId;
  final int homeworkId;

  final DateTime? occurrenceStart;

  DeleteHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.homeworkId,
    this.occurrenceStart,
  });
}
