import 'package:heliumedu/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_request_model.dart';

abstract class ExternalCalendarRepository {
  Future<List<ExternalCalendarModel>> getAllExternalCalendars();
  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required int calendarId,
    DateTime? start,
    DateTime? end,
  });
  Future<ExternalCalendarModel> addExternalCalendar({
    required ExternalCalendarRequestModel payload,
  });
  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  });
  Future<void> deleteExternalCalendar({
    required int calendarId,
  });
}
