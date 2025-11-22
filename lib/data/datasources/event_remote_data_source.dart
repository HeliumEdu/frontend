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
import 'package:helium_mobile/data/models/planner/event_request_model.dart';
import 'package:helium_mobile/data/models/planner/event_response_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventResponseModel>> getAllEvents({
    String? start,
    String? end,
    String? startGte,
    String? endLt,
    String? ordering,
    String? search,
    String? title,
  });

  Future<EventResponseModel> createEvent({required EventRequestModel request});

  Future<EventResponseModel> getEventById({required int eventId});

  Future<EventResponseModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  });

  Future<void> deleteEvent({required int eventId});
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final DioClient dioClient;

  EventRemoteDataSourceImpl({required this.dioClient});

  AppException _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 400) {
        // Validation error
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
        return ServerException(message: 'Event not found');
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
  Future<List<EventResponseModel>> getAllEvents({
    String? start,
    String? end,
    String? startGte,
    String? endLt,
    String? ordering,
    String? search,
    String? title,
  }) async {
    try {
      print('📅 Fetching all events...');

      // Build query parameters
      final Map<String, dynamic> queryParameters = {};
      if (start != null) queryParameters['start'] = start;
      if (end != null) queryParameters['end'] = end;
      if (startGte != null) queryParameters['start__gte'] = startGte;
      if (endLt != null) queryParameters['end__lt'] = endLt;
      if (ordering != null) queryParameters['ordering'] = ordering;
      if (search != null) queryParameters['search'] = search;
      if (title != null) queryParameters['title'] = title;

      final response = await dioClient.dio.get(
        NetworkUrl.eventsUrl,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          print('✅ Fetched ${data.length} event(s)');
          return data.map((json) => EventResponseModel.fromJson(json)).toList();
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch events: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      print('❌ Error fetching all events: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<EventResponseModel> createEvent({
    required EventRequestModel request,
  }) async {
    try {
      print('📝 Creating event...');
      final response = await dioClient.dio.post(
        NetworkUrl.eventsUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Event created successfully');
        return EventResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create event: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Error creating event: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<EventResponseModel> getEventById({required int eventId}) async {
    try {
      print('📅 Fetching event by ID: $eventId');
      final response = await dioClient.dio.get(
        NetworkUrl.eventByIdUrl(eventId),
      );

      if (response.statusCode == 200) {
        print('✅ Event fetched successfully');
        return EventResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch event: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Error fetching event: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<EventResponseModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  }) async {
    try {
      print('📝 Updating event: $eventId');
      final response = await dioClient.dio.put(
        NetworkUrl.eventByIdUrl(eventId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        print('✅ Event updated successfully');
        return EventResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update event: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Error updating event: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteEvent({required int eventId}) async {
    try {
      print('🗑️ Deleting event: $eventId');
      final response = await dioClient.dio.delete(
        NetworkUrl.eventByIdUrl(eventId),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Event deleted successfully');
      } else {
        throw ServerException(
          message: 'Failed to delete event: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Error deleting event: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }
}
