// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/models/planner/external_calendar_event_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_request_model.dart';

abstract class ExternalCalendarRepository {
  Future<List<ExternalCalendarModel>> getAllExternalCalendars();

  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    DateTime? from,
    DateTime? to,
    String? search,
  });

  Future<ExternalCalendarModel> addExternalCalendar({
    required ExternalCalendarRequestModel payload,
  });

  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  });

  Future<void> deleteExternalCalendar({required int calendarId});
}
