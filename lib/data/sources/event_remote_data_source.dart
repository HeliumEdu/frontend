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
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class EventRemoteDataSource extends BaseDataSource {
  Future<List<EventModel>> getEvents({
    DateTime? from,
    DateTime? to,
    String? search,
    String? title,
    bool forceRefresh = false,
  });

  Future<EventModel> getEvent({required int id, bool forceRefresh = false});

  Future<EventModel> createEvent({required EventRequestModel request});

  Future<EventModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  });

  Future<void> deleteEvent({required int eventId});

  Future<void> deleteAllEvents();
}

class EventRemoteDataSourceImpl extends EventRemoteDataSource {
  final DioClient dioClient;

  EventRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<EventModel>> getEvents({
    DateTime? from,
    DateTime? to,
    String? search,
    String? title,
    bool forceRefresh = false,
  }) async {
    try {
      _log.info('Fetching Events ...');

      final Map<String, dynamic> queryParameters = {};
      if (from != null) queryParameters['from'] = from;
      if (to != null) queryParameters['to'] = to;
      if (search != null) queryParameters['search'] = search;
      if (title != null) queryParameters['title'] = title;

      final response = await dioClient.dio.get(
        ApiUrl.plannerEventsListUrl,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        options: forceRefresh
            ? dioClient.cacheService.forceRefreshOptions()
            : null,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          final events = data.map((json) => EventModel.fromJson(json)).toList();
          _log.info('... fetched ${events.length} Event(s)');
          return events;
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
  Future<EventModel> getEvent({
    required int id,
    bool forceRefresh = false,
  }) async {
    try {
      _log.info('Fetching Event $id ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerEventsDetailsUrl(id),
        options: forceRefresh
            ? dioClient.cacheService.forceRefreshOptions()
            : null,
      );

      if (response.statusCode == 200) {
        _log.info('... Event $id fetched');
        return EventModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch event: ${response.statusCode}',
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
  Future<EventModel> createEvent({required EventRequestModel request}) async {
    try {
      _log.info('Creating Event ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerEventsListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final event = EventModel.fromJson(response.data);
        _log.info('... Event ${event.id} created');
        await dioClient.cacheService.invalidateAll();
        return event;
      } else {
        throw ServerException(
          message: 'Failed to create event: ${response.statusCode}',
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
  Future<EventModel> updateEvent({
    required int eventId,
    required EventRequestModel request,
  }) async {
    try {
      _log.info('Updating Event $eventId ...');
      final response = await dioClient.dio.patch(
        ApiUrl.plannerEventsDetailsUrl(eventId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Event $eventId updated');
        await dioClient.cacheService.invalidateAll();
        return EventModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update event: ${response.statusCode}',
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
  Future<void> deleteEvent({required int eventId}) async {
    try {
      _log.info('Deleting Event $eventId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerEventsDetailsUrl(eventId),
      );

      if (response.statusCode == 204) {
        _log.info('... Event $eventId deleted');
        await dioClient.cacheService.invalidateAll();
      } else {
        throw ServerException(
          message: 'Failed to delete event: ${response.statusCode}',
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
  Future<void> deleteAllEvents() async {
    try {
      _log.info('Deleting all Events ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerEventsDeleteAll,
      );

      if (response.statusCode == 204) {
        _log.info('... all Events deleted');
        await dioClient.cacheService.invalidateAll();
      } else {
        throw ServerException(
          message: 'Failed to delete all events: ${response.statusCode}',
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
}
