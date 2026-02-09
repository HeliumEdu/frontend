// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class ExternalCalendarRemoteDataSource extends BaseDataSource {
  Future<List<ExternalCalendarModel>> getExternalCalendars();

  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required DateTime from,
    required DateTime to,
    String? search,
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

class ExternalCalendarRemoteDataSourceImpl
    extends ExternalCalendarRemoteDataSource {
  final DioClient dioClient;

  ExternalCalendarRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ExternalCalendarModel>> getExternalCalendars() async {
    try {
      _log.info('Fetching ExternalCalendars ...');

      final response = await dioClient.dio.get(
        ApiUrl.feedExternalCalendarsListUrl,
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> rawList;

        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          final results = data['results'];
          if (results is List) {
            rawList = results;
          } else {
            rawList = const [];
          }
        } else {
          rawList = const [];
        }

        final calendars = rawList
            .map((json) => ExternalCalendarModel.fromJson(json))
            .toList();

        _log.info('... fetched ${calendars.length} ExternalCalendar(s)');
        return calendars;
      } else {
        throw ServerException(message: 'Failed to fetch external calendars');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required DateTime from,
    required DateTime to,
    String? search,
  }) async {
    try {
      _log.info('Fetching ExternalCalendarEvents ...');

      final Map<String, dynamic> queryParameters = {
        'from': HeliumDateTime.formatDateForApi(from),
        'to': HeliumDateTime.formatDateForApi(to),
      };
      if (search != null) queryParameters['search'] = search;

      // TODO: Enhancement: consider just hitting iCal directly for a better path, and to reduce load on our backend

      final response = await dioClient.dio.get(
        ApiUrl.feedExternalCalendarsEventsListUrl,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          final events = data
              .map((json) => ExternalCalendarEventModel.fromJson(json))
              .toList();
          _log.info('... fetched ${events.length} ExternalCalendarEvent(s)');
          return events;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch external calendar events',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<ExternalCalendarModel> createExternalCalendar({
    required ExternalCalendarRequestModel payload,
  }) async {
    try {
      _log.info('Creating ExternalCalendar ...');

      final response = await dioClient.dio.post(
        ApiUrl.feedExternalCalendarsListUrl,
        data: payload.toJson(),
      );

      if (response.statusCode == 201) {
        final calendar = ExternalCalendarModel.fromJson(response.data);
        _log.info('... ExternalCalendar ${calendar.id} created');
        return calendar;
      } else {
        throw ServerException(message: 'Failed to add external calendar');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  }) async {
    try {
      _log.info('Updating ExternalCalendar $calendarId ...');

      final response = await dioClient.dio.put(
        ApiUrl.feedExternalCalendarDetailUrl(calendarId),
        data: payload.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... ExternalCalendar $calendarId updated');
        return ExternalCalendarModel.fromJson(response.data);
      } else {
        throw ServerException(message: 'Failed to update external calendar');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteExternalCalendar({required int calendarId}) async {
    try {
      _log.info('Deleting ExternalCalendar $calendarId ...');

      final response = await dioClient.dio.delete(
        ApiUrl.feedExternalCalendarDetailUrl(calendarId),
      );

      if (response.statusCode == 204) {
        _log.info('... ExternalCalendar $calendarId deleted');
        return;
      } else {
        throw ServerException(message: 'Failed to delete external calendar');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }
}
