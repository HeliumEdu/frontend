// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class ReminderRemoteDataSource extends BaseDataSource {
  Future<List<ReminderModel>> getReminders({
    int? homeworkId,
    int? eventId,
    int? courseId,
    bool? sent,
    bool? dismissed,
    int? type,
    DateTime? startOfRange,
    bool forceRefresh = false,
  });

  Future<ReminderModel> createReminder(ReminderRequestModel request);

  Future<ReminderModel> updateReminder(int id, ReminderRequestModel request);

  Future<void> deleteReminder(int id);
}

class ReminderRemoteDataSourceImpl extends ReminderRemoteDataSource {
  final DioClient dioClient;

  ReminderRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ReminderModel>> getReminders({
    int? homeworkId,
    int? eventId,
    int? courseId,
    bool? sent,
    bool? dismissed,
    int? type,
    DateTime? startOfRange,
    bool forceRefresh = false,
  }) async {
    try {
      final parentInfo = eventId != null
          ? 'Event $eventId'
          : homeworkId != null
              ? 'Homework $homeworkId'
              : courseId != null
                  ? 'Course $courseId'
                  : 'all';
      _log.info('Fetching Reminders for $parentInfo ...');

      final Map<String, dynamic> queryParameters = {};
      if (homeworkId != null) queryParameters['homework'] = homeworkId;
      if (eventId != null) queryParameters['event'] = eventId;
      if (courseId != null) queryParameters['course'] = courseId;
      if (sent != null) queryParameters['sent'] = sent;
      if (dismissed != null) queryParameters['dismissed'] = dismissed;
      if (type != null) queryParameters['type'] = type;
      if (startOfRange != null) {
        queryParameters['start_of_range__lte'] =
            startOfRange.toUtc().toIso8601String();
      }

      final response = await dioClient.dio.get(
        ApiUrl.plannerRemindersListUrl,
        queryParameters: queryParameters,
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final reminders =
            data.map((json) => ReminderModel.fromJson(json)).toList();
        _log.info('... fetched ${reminders.length} Reminder(s)');
        return reminders;
      } else {
        throw ServerException(
          message: 'Failed to fetch reminders: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<ReminderModel> createReminder(ReminderRequestModel request) async {
    try {
      _log.info('Creating Reminder ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerRemindersListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final reminder = ReminderModel.fromJson(response.data);
        _log.info('... Reminder ${reminder.id} created');
        await dioClient.cacheService.invalidateAll();
        unawaited(AnalyticsService().logEvent(name: 'reminder_created', parameters: {'category': 'feature_interaction'}));
        return reminder;
      } else {
        throw ServerException(
          message: 'Failed to create reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<ReminderModel> updateReminder(
    int id,
    ReminderRequestModel request,
  ) async {
    try {
      _log.info('Updating Reminder $id ...');
      final response = await dioClient.dio.put(
        ApiUrl.plannerRemindersDetailsUrl(id),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Reminder $id updated');
        await dioClient.cacheService.invalidateAll();
        return ReminderModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<void> deleteReminder(int id) async {
    try {
      _log.info('Deleting Reminder $id ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerRemindersDetailsUrl(id),
      );

      if (response.statusCode == 204) {
        _log.info('... Reminder $id deleted');
        await dioClient.cacheService.invalidateAll();
      } else {
        throw ServerException(
          message: 'Failed to delete reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }
}
