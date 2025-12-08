// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/event_request_model.dart';
import 'package:heliumapp/data/models/planner/event_response_model.dart';

abstract class EventRepository {
  Future<List<EventResponseModel>> getAllEvents({
    String? from,
    String? to,
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
