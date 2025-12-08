// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/models/planner/event_request_model.dart';

abstract class EventEvent {}

class FetchAllEventsEvent extends EventEvent {
  final String? from;
  final String? to;
  final String? ordering;
  final String? search;
  final String? title;

  FetchAllEventsEvent({
    this.from,
    this.to,
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
