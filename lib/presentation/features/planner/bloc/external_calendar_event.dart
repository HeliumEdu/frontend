// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class ExternalCalendarEvent extends BaseEvent {
  ExternalCalendarEvent({required super.origin});
}

/// Clears all external calendar state. Dispatched on logout so per-user data
/// does not carry into the next session.
class ResetExternalCalendarsEvent extends ExternalCalendarEvent {
  ResetExternalCalendarsEvent() : super(origin: EventOrigin.bloc);
}

class FetchExternalCalendarsEvent extends ExternalCalendarEvent {
  final bool forceRefresh;

  FetchExternalCalendarsEvent({required super.origin, this.forceRefresh = false});
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
