// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/datasources/external_calendar_remote_data_source.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_event_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_request_model.dart';
import 'package:helium_mobile/domain/repositories/external_calendar_repository.dart';

class ExternalCalendarRepositoryImpl implements ExternalCalendarRepository {
  final ExternalCalendarRemoteDataSource remoteDataSource;

  ExternalCalendarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ExternalCalendarModel>> getAllExternalCalendars() async {
    return await remoteDataSource.getAllExternalCalendars();
  }

  @override
  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    DateTime? from,
    DateTime? to,
    String? search
  }) async {
    return await remoteDataSource.getExternalCalendarEvents(
      from: from,
      to: to,
      search: search
    );
  }

  @override
  Future<ExternalCalendarModel> addExternalCalendar({
    required ExternalCalendarRequestModel payload,
  }) async {
    return await remoteDataSource.addExternalCalendar(payload: payload);
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
