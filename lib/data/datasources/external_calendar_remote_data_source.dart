// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/network_urls.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_event_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_request_model.dart';
import 'package:intl/intl.dart';

abstract class ExternalCalendarRemoteDataSource {
  Future<List<ExternalCalendarModel>> getAllExternalCalendars();

  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required int calendarId,
    DateTime? start,
    DateTime? end,
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

class ExternalCalendarRemoteDataSourceImpl
    implements ExternalCalendarRemoteDataSource {
  final DioClient dioClient;

  ExternalCalendarRemoteDataSourceImpl({required this.dioClient});

  AppException _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 400) {
        if (data is Map<String, dynamic>) {
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => '$key: $e'));
            } else {
              errors.add('$key: $value');
            }
          });
          return ValidationException(message: errors.join(', '));
        }
        return ValidationException(message: 'Invalid request data');
      } else if (statusCode == 401) {
        return UnauthorizedException(message: 'Unauthorized access');
      } else if (statusCode == 404) {
        return ServerException(message: 'External calendar not found');
      } else if (statusCode != null && statusCode >= 500) {
        return ServerException(message: 'Server error occurred');
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: 'Connection timeout');
    }

    return NetworkException(message: 'Network error occurred');
  }

  @override
  Future<List<ExternalCalendarModel>> getAllExternalCalendars() async {
    try {
      print('📅 Fetching all external calendars...');

      final response = await dioClient.dio.get(NetworkUrl.externalCalendarsUrl);

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

        print('✅ Fetched ${calendars.length} external calendars');
        return calendars;
      } else {
        throw ServerException(message: 'Failed to fetch external calendars');
      }
    } on DioException catch (e) {
      print('❌ DioException in getAllExternalCalendars: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception in getAllExternalCalendars: $e');
      throw ServerException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ExternalCalendarEventModel>> getExternalCalendarEvents({
    required int calendarId,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      print('📅 Fetching events for external calendar $calendarId...');

      final events = <ExternalCalendarEventModel>[];
      String? nextUrl;

      String formatDate(DateTime value) =>
          DateFormat('MMM dd, yyyy').format(value.toUtc());

      Map<String, dynamic>? buildQueryParams() {
        final params = <String, dynamic>{'limit': 500};
        if (start != null) params['start__gte'] = formatDate(start);
        if (end != null) params['end__lt'] = formatDate(end);
        return params;
      }

      do {
        final response = nextUrl == null
            ? await dioClient.dio.get(
                NetworkUrl.externalCalendarEventsUrl(calendarId),
                queryParameters: buildQueryParams(),
              )
            : await dioClient.dio.getUri(Uri.parse(nextUrl));

        if (response.statusCode == 200) {
          final dynamic data = response.data;
          final List<dynamic> results;

          if (data is List) {
            results = data;
            nextUrl = null;
          } else if (data is Map<String, dynamic>) {
            final rawResults = data['results'];
            if (rawResults is List) {
              results = rawResults;
            } else {
              results = const [];
            }
            final next = data['next'];
            nextUrl = next is String && next.isNotEmpty ? next : null;
          } else {
            results = const [];
            nextUrl = null;
          }

          // Inject the calendar ID into each event JSON before parsing
          events.addAll(
            results.map((json) {
              // Add the external_calendar field to the JSON
              if (json is Map<String, dynamic>) {
                json['external_calendar'] = calendarId;
              }
              return ExternalCalendarEventModel.fromJson(json);
            }).toList(),
          );
        } else {
          throw ServerException(
            message: 'Failed to fetch external calendar events',
          );
        }
      } while (nextUrl != null);

      print(
        '✅ Fetched ${events.length} events for external calendar $calendarId',
      );
      return events;
    } on DioException catch (e) {
      print('❌ DioException in getExternalCalendarEvents: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception in getExternalCalendarEvents: $e');
      throw ServerException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<ExternalCalendarModel> addExternalCalendar({
    required ExternalCalendarRequestModel payload,
  }) async {
    try {
      print('📅 Adding external calendar: ${payload.title}');
      print('🔗 URL: ${payload.url}');

      final response = await dioClient.dio.post(
        NetworkUrl.externalCalendarsUrl,
        data: payload.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final calendar = ExternalCalendarModel.fromJson(response.data);
        print('✅ External calendar added successfully: ${calendar.title}');
        return calendar;
      } else {
        throw ServerException(message: 'Failed to add external calendar');
      }
    } on DioException catch (e) {
      print('❌ DioException in addExternalCalendar: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception in addExternalCalendar: $e');
      throw ServerException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<ExternalCalendarModel> updateExternalCalendar({
    required int calendarId,
    required ExternalCalendarRequestModel payload,
  }) async {
    try {
      print(
        '📅 Updating external calendar: ${payload.title} (ID: $calendarId)',
      );

      final response = await dioClient.dio.put(
        NetworkUrl.externalCalendarDetailUrl(calendarId),
        data: payload.toJson(),
      );

      if (response.statusCode == 200) {
        final calendar = ExternalCalendarModel.fromJson(response.data);
        print('✅ External calendar updated successfully: ${calendar.title}');
        return calendar;
      } else {
        throw ServerException(message: 'Failed to update external calendar');
      }
    } on DioException catch (e) {
      print('❌ DioException in updateExternalCalendar: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception in updateExternalCalendar: $e');
      throw ServerException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteExternalCalendar({required int calendarId}) async {
    try {
      print('🗑️ Deleting external calendar ID: $calendarId');

      final response = await dioClient.dio.delete(
        NetworkUrl.externalCalendarDetailUrl(calendarId),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ External calendar deleted successfully: $calendarId');
        return;
      } else {
        throw ServerException(message: 'Failed to delete external calendar');
      }
    } on DioException catch (e) {
      print('❌ DioException in deleteExternalCalendar: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception in deleteExternalCalendar: $e');
      throw ServerException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}
