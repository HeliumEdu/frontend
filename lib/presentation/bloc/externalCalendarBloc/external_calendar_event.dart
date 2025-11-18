import 'package:helium_student_flutter/data/models/planner/external_calendar_request_model.dart';

abstract class ExternalCalendarEvent {}

class FetchAllExternalCalendarsEvent extends ExternalCalendarEvent {}

class FetchExternalCalendarEventsEvent extends ExternalCalendarEvent {
  final int calendarId;

  FetchExternalCalendarEventsEvent({required this.calendarId});
}

class FetchAllExternalCalendarEventsEvent extends ExternalCalendarEvent {}

class CreateExternalCalendarEvent extends ExternalCalendarEvent {
  final ExternalCalendarRequestModel payload;

  CreateExternalCalendarEvent({required this.payload});
}

class UpdateExternalCalendarEvent extends ExternalCalendarEvent {
  final int calendarId;
  final ExternalCalendarRequestModel payload;

  UpdateExternalCalendarEvent({
    required this.calendarId,
    required this.payload,
  });
}

class DeleteExternalCalendarEvent extends ExternalCalendarEvent {
  final int calendarId;

  DeleteExternalCalendarEvent({required this.calendarId});
}
