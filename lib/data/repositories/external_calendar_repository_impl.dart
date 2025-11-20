import 'package:heliumedu/data/datasources/external_calendar_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_request_model.dart';
import 'package:heliumedu/domain/repositories/external_calendar_repository.dart';

class ExternalCalendarRepositoryImpl implements ExternalCalendarRepository {
  final ExternalCalendarRemoteDataSource remoteDataSource;

  ExternalCalendarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ExternalCalendarModel>> getAllExternalCalendars() async {
    return await remoteDataSource.getAllExternalCalendars();
  }

  @override
  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required int calendarId,
    DateTime? start,
    DateTime? end,
  }) async {
    return await remoteDataSource.getExternalCalendarEvents(
      calendarId: calendarId,
      start: start,
      end: end,
    );
  }

  @override
  Future<ExternalCalendarModel> addExternalCalendar({
    required ExternalCalendarRequestModel payload,
  }) async {
    return await remoteDataSource.addExternalCalendar(payload: payload);
  }

  @override
  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  }) async {
    return await remoteDataSource.updateExternalCalendar(
      calendarId: calendarId,
      payload: payload,
    );
  }

  @override
  Future<void> deleteExternalCalendar({required int calendarId}) async {
    await remoteDataSource.deleteExternalCalendar(calendarId: calendarId);
  }
}
