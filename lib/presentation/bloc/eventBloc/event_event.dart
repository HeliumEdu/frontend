import 'package:helium_student_flutter/data/models/planner/event_request_model.dart';

abstract class EventEvent {}

class FetchAllEventsEvent extends EventEvent {
  final String? start;
  final String? end;
  final String? startGte;
  final String? endLt;
  final String? ordering;
  final String? search;
  final String? title;

  FetchAllEventsEvent({
    this.start,
    this.end,
    this.startGte,
    this.endLt,
    this.ordering,
    this.search,
    this.title,
  });
}

class CreateEventEvent extends EventEvent {
  final EventRequestModel request;

  CreateEventEvent({required this.request});
}

class FetchEventByIdEvent extends EventEvent {
  final int eventId;

  FetchEventByIdEvent({required this.eventId});
}

class UpdateEventEvent extends EventEvent {
  final int eventId;
  final EventRequestModel request;

  UpdateEventEvent({required this.eventId, required this.request});
}

class DeleteEventEvent extends EventEvent {
  final int eventId;

  DeleteEventEvent({required this.eventId});
}
