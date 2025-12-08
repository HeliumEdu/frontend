// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_response_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class ReminderRemoteDataSource {
  Future<ReminderResponseModel> createReminder(ReminderRequestModel request);

  Future<List<ReminderResponseModel>> getReminders();

  Future<ReminderResponseModel> getReminderById(int reminderId);

  Future<ReminderResponseModel> updateReminder(
    int reminderId,
    ReminderRequestModel request,
  );

  Future<void> deleteReminder(int reminderId);
}

class ReminderRemoteDataSourceImpl implements ReminderRemoteDataSource {
  final DioClient dioClient;

  ReminderRemoteDataSourceImpl({required this.dioClient});

  HeliumException _handleDioError(DioException e) {
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
        return ServerException(message: 'Reminder not found');
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
  Future<ReminderResponseModel> createReminder(
    ReminderRequestModel request,
  ) async {
    try {
      log.info('📝 Creating reminder...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerRemindersListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log.info('✅ Reminder created successfully');
        return ReminderResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      log.info('❌ Error creating reminder: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<ReminderResponseModel>> getReminders() async {
    try {
      final response = await dioClient.dio.get(ApiUrl.plannerRemindersListUrl);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => ReminderResponseModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch reminders: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<ReminderResponseModel> getReminderById(int reminderId) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.plannerRemindersDetailsUrl(reminderId),
      );

      if (response.statusCode == 200) {
        return ReminderResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<ReminderResponseModel> updateReminder(
    int reminderId,
    ReminderRequestModel request,
  ) async {
    try {
      log.info('📝 Updating reminder with ID: $reminderId');
      log.info('📋 PUT ${ApiUrl.plannerRemindersDetailsUrl(reminderId)}');
      final response = await dioClient.dio.put(
        ApiUrl.plannerRemindersDetailsUrl(reminderId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        log.info('✅ Reminder updated successfully via PUT API');
        return ReminderResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      log.info('❌ Error updating reminder: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteReminder(int reminderId) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.plannerRemindersDetailsUrl(reminderId),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        log.info('✅ Reminder deleted successfully');
      } else {
        throw ServerException(
          message: 'Failed to delete reminder: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }
}
