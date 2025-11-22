// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/datasources/event_remote_data_source.dart';
import 'package:helium_mobile/data/models/planner/event_request_model.dart';
import 'package:helium_mobile/data/models/planner/event_response_model.dart';
import 'package:helium_mobile/domain/repositories/event_repository.dart';

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
