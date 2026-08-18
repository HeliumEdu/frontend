import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EventModel>> getEvents({
    DateTime? from,
    DateTime? to,
    String? search,
    String? title,
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getEvents(
      from: from,
      to: to,
      search: search,
      title: title,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<EventModel> getEvent({
    required int id,
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getEvent(id: id, forceRefresh: forceRefresh);
  }

  @override
  Future<EventModel> createEvent({required EventRequestModel request}) async {
    return remoteDataSource.createEvent(request: request);
  }

  @override
  Future<EventModel> cloneEvent({required int eventId}) async {
    return remoteDataSource.cloneEvent(eventId: eventId);
  }

  @override
  Future<EventModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  }) async {
    return remoteDataSource.updateEvent(
      eventId: eventId,
      request: request,
    );
  }

  @override
  Future<void> deleteEvent({required int eventId}) async {
    return remoteDataSource.deleteEvent(eventId: eventId);
  }

  @override
  Future<void> deleteAllEvents() async {
    return remoteDataSource.deleteAllEvents();
  }
}
