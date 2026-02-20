// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';

abstract class EventRepository {
  Future<List<EventModel>> getEvents({
    DateTime? from,
    DateTime? to,
    String? search,
    String? title,
    bool forceRefresh = false,
  });

  Future<EventModel> getEvent({
    required int id,
    bool forceRefresh = false,
  });

  Future<EventModel> createEvent({required EventRequestModel request});

  Future<EventModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  });

  Future<void> deleteEvent({required int eventId});

  Future<void> deleteAllEvents();
}
