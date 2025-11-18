import 'package:helium_student_flutter/data/datasources/event_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/event_request_model.dart';
import 'package:helium_student_flutter/data/models/planner/event_response_model.dart';
import 'package:helium_student_flutter/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EventResponseModel>> getAllEvents({
    String? start,
    String? end,
    String? startGte,
    String? endLt,
    String? ordering,
    String? search,
    String? title,
  }) async {
    return await remoteDataSource.getAllEvents(
      start: start,
      end: end,
      startGte: startGte,
      endLt: endLt,
      ordering: ordering,
      search: search,
      title: title,
    );
  }

  @override
  Future<EventResponseModel> createEvent({
    required EventRequestModel request,
  }) async {
    return await remoteDataSource.createEvent(request: request);
  }

  @override
  Future<EventResponseModel> getEventById({required int eventId}) async {
    return await remoteDataSource.getEventById(eventId: eventId);
  }

  @override
  Future<EventResponseModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  }) async {
    return await remoteDataSource.updateEvent(
      eventId: eventId,
      request: request,
    );
  }

  @override
  Future<void> deleteEvent({required int eventId}) async {
    return await remoteDataSource.deleteEvent(eventId: eventId);
  }
}
