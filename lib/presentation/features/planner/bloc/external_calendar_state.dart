// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class ExternalCalendarState extends BaseState {
  ExternalCalendarState({required super.origin, super.message});
}

class ExternalCalendarInitial extends ExternalCalendarState {
  ExternalCalendarInitial({required super.origin});
}

class ExternalCalendarsLoading extends ExternalCalendarState {
  ExternalCalendarsLoading({required super.origin});
}

class ExternalCalendarsError extends ExternalCalendarState {
  ExternalCalendarsError({required super.origin, required super.message});
}

class ExternalCalendarsFetched extends ExternalCalendarState {
  final List<ExternalCalendarModel> externalCalendars;

  ExternalCalendarsFetched({
    required super.origin,
    required this.externalCalendars,
  });
}

class ExternalCalendarEventsFetched extends ExternalCalendarState {
  final List<ExternalCalendarEventModel> events;

  ExternalCalendarEventsFetched({required super.origin, required this.events});
}

class ExternalCalendarCreated extends ExternalCalendarState {
  final ExternalCalendarModel externalCalendar;

  ExternalCalendarCreated({
    required super.origin,
    required this.externalCalendar,
  });
}

class ExternalCalendarUpdated extends ExternalCalendarState {
  final ExternalCalendarModel externalCalendar;

  ExternalCalendarUpdated({
    required super.origin,
    required this.externalCalendar,
  });
}

class ExternalCalendarDeleted extends ExternalCalendarState {
  final int id;

  ExternalCalendarDeleted({required super.origin, required this.id});
}
