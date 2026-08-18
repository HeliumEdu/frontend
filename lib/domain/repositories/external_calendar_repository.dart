// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';

abstract class ExternalCalendarRepository {
  Future<List<ExternalCalendarModel>> getExternalCalendars({
    bool forceRefresh = false,
  });

  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required DateTime from,
    required DateTime to,
    String? search,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<ExternalCalendarModel> createExternalCalendar({
    required ExternalCalendarRequestModel payload,
  });

  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  });

  Future<void> deleteExternalCalendar({required int calendarId});
}
