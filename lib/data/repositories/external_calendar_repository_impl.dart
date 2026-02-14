// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';

class ExternalCalendarRepositoryImpl implements ExternalCalendarRepository {
  final ExternalCalendarRemoteDataSource remoteDataSource;

  ExternalCalendarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ExternalCalendarModel>> getExternalCalendars({
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getExternalCalendars(forceRefresh: forceRefresh);
  }

  @override
  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required DateTime from,
    required DateTime to,
    String? search,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getExternalCalendarEvents(
      from: from,
      to: to,
      search: search,
      shownOnCalendar: shownOnCalendar,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<ExternalCalendarModel> createExternalCalendar({
    required ExternalCalendarRequestModel payload,
  }) async {
    return await remoteDataSource.createExternalCalendar(payload: payload);
  }

  @override
  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  }) async {
    return await remoteDataSource.updateExternalCalendar(
      calendarId: calendarId,
      payload: payload,
    );
  }

  @override
  Future<void> deleteExternalCalendar({required int calendarId}) async {
    await remoteDataSource.deleteExternalCalendar(calendarId: calendarId);
  }
}
