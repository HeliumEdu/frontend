import 'package:helium_student_flutter/data/models/planner/event_request_model.dart';
import 'package:helium_student_flutter/data/models/planner/event_response_model.dart';

abstract class EventRepository {
  Future<List<EventResponseModel>> getAllEvents({
    String? start,
    String? end,
    String? startGte,
    String? endLt,
    String? ordering,
    String? search,
    String? title,
  });

  Future<EventResponseModel> createEvent({required EventRequestModel request});

  Future<EventResponseModel> getEventById({required int eventId});

  Future<EventResponseModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  });

  Future<void> deleteEvent({required int eventId});
}
