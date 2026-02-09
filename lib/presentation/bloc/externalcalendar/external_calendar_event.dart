// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';

abstract class ExternalCalendarEvent extends BaseEvent {
  ExternalCalendarEvent({required super.origin});
}

class FetchExternalCalendarsEvent extends ExternalCalendarEvent {
  FetchExternalCalendarsEvent({required super.origin});
}

class FetchExternalCalendarEventsEvent extends ExternalCalendarEvent {
  final DateTime from;
  final DateTime to;
  final String? search;

  FetchExternalCalendarEventsEvent({
    required super.origin,
    required this.from,
    required this.to,
    this.search,
  });
}

class CreateExternalCalendarEvent extends ExternalCalendarEvent {
  final ExternalCalendarRequestModel request;

  CreateExternalCalendarEvent({required super.origin, required this.request});
}

class UpdateExternalCalendarEvent extends ExternalCalendarEvent {
  final int id;
  final ExternalCalendarRequestModel request;

  UpdateExternalCalendarEvent({
    required super.origin,
    required this.id,
    required this.request,
  });
}

class DeleteExternalCalendarEvent extends ExternalCalendarEvent {
  final int id;

  DeleteExternalCalendarEvent({required super.origin, required this.id});
}
