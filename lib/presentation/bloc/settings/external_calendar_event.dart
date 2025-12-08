// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/external_calendar_request_model.dart';

abstract class ExternalCalendarEvent {}

class FetchAllExternalCalendarsEvent extends ExternalCalendarEvent {}

class FetchExternalCalendarEventsEvent extends ExternalCalendarEvent {
  final String? from;
  final String? to;
  final String? search;

  FetchExternalCalendarEventsEvent({this.from, this.to, this.search});
}

class CreateExternalCalendarEvent extends ExternalCalendarEvent {
  final ExternalCalendarRequestModel payload;

  CreateExternalCalendarEvent({required this.payload});
}

class UpdateExternalCalendarEvent extends ExternalCalendarEvent {
  final int calendarId;
  final ExternalCalendarRequestModel payload;

  UpdateExternalCalendarEvent({
    required this.calendarId,
    required this.payload,
  });
}

class DeleteExternalCalendarEvent extends ExternalCalendarEvent {
  final int calendarId;

  DeleteExternalCalendarEvent({required this.calendarId});
}
