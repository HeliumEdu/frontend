// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_model.dart';

abstract class ExternalCalendarState {}

class ExternalCalendarInitial extends ExternalCalendarState {}

// Fetch External Calendars States
class ExternalCalendarsLoading extends ExternalCalendarState {}

class ExternalCalendarsLoaded extends ExternalCalendarState {
  final List<ExternalCalendarModel> calendars;
  ExternalCalendarsLoaded({required this.calendars});
}

class ExternalCalendarActionInProgress extends ExternalCalendarState {}

class ExternalCalendarActionSuccess extends ExternalCalendarState {
  final String message;
  final List<ExternalCalendarModel>? calendars;

  ExternalCalendarActionSuccess({required this.message, this.calendars});
}

class ExternalCalendarActionError extends ExternalCalendarState {
  final String message;
  ExternalCalendarActionError({required this.message});
}

class ExternalCalendarsError extends ExternalCalendarState {
  final String message;
  ExternalCalendarsError({required this.message});
}

// Fetch External Calendar Events States
class ExternalCalendarEventsLoading extends ExternalCalendarState {}

class ExternalCalendarEventsLoaded extends ExternalCalendarState {
  final List<ExternalCalendarEventModel> events;
  ExternalCalendarEventsLoaded({required this.events});
}

class ExternalCalendarEventsError extends ExternalCalendarState {
  final String message;
  ExternalCalendarEventsError({required this.message});
}

// Combined State for All External Calendar Events
class AllExternalCalendarEventsLoading extends ExternalCalendarState {}

class AllExternalCalendarEventsLoaded extends ExternalCalendarState {
  final List<ExternalCalendarEventModel> events;
  final List<ExternalCalendarModel> calendars;
  final Map<int, List<ExternalCalendarEventModel>> eventsByCalendar;

  AllExternalCalendarEventsLoaded({
    required this.events,
    required this.calendars,
    required this.eventsByCalendar,
  });
}

class AllExternalCalendarEventsError extends ExternalCalendarState {
  final String message;
  AllExternalCalendarEventsError({required this.message});
}
