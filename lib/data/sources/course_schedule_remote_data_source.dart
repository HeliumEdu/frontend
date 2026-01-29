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
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class CourseScheduleRemoteDataSource extends BaseDataSource {
  Future<List<CourseScheduleEventModel>> getCourseScheduleEvents({
    required DateTime from,
    required DateTime to,
    String? search,
  });

  Future<List<CourseScheduleModel>> getCourseSchedules();

  Future<CourseScheduleModel> getCourseScheduleForCourse(
    int groupId,
    int courseId,
  );

  Future<CourseScheduleModel> createCourseSchedule(
    int groupId,
    int courseId,
    CourseScheduleRequestModel request,
  );

  Future<CourseScheduleModel> updateCourseSchedule(
    int groupId,
    int courseId,
    int scheduleId,
    CourseScheduleRequestModel request,
  );
}

class CourseScheduleRemoteDataSourceImpl
    extends CourseScheduleRemoteDataSource {
  final DioClient dioClient;

  CourseScheduleRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CourseScheduleEventModel>> getCourseScheduleEvents({
    required DateTime from,
    required DateTime to,
    String? search,
  }) async {
    try {
      log.info('Fetching CourseScheduleEvents ...');

      final Map<String, dynamic> queryParameters = {
        'from': HeliumDateTime.formatDateForApi(from),
        'to': HeliumDateTime.formatDateForApi(to),
      };
      if (search != null) queryParameters['search'] = search;

      final response = await dioClient.dio.get(
        ApiUrl.plannerSchedulesEvents,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          final events = data
              .map((json) => CourseScheduleEventModel.fromJson(json))
              .toList();
          log.info('... fetched ${events.length} CourseScheduleEvent(s)');
          return events;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch course schedule events',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<CourseScheduleModel>> getCourseSchedules() async {
    try {
      log.info('Fetching CourseSchedules ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseSchedulesUrl,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final schedules = (response.data as List)
              .map((course) => CourseScheduleModel.fromJson(course))
              .toList();
          log.info('... fetched ${schedules.length} CourseSchedule(s)');
          return schedules;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch courses',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseScheduleModel> getCourseScheduleForCourse(
    int groupId,
    int courseId,
  ) async {
    try {
      log.info('Fetching CourseSchedule for Course $courseId ...');

      final schedulesResponse = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesSchedulesListUrl(groupId, courseId),
      );

      if (schedulesResponse.data.length == 0) {
        throw NotFoundException(message: 'No Schedule found for Course');
      }

      final scheduleId = schedulesResponse.data[0]['id'];
      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesSchedulesDetailsUrl(
          groupId,
          courseId,
          scheduleId,
        ),
      );

      if (response.statusCode == 200) {
        log.info('... CourseSchedule $scheduleId fetched for Course $courseId');
        return CourseScheduleModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch schedule details',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseScheduleModel> createCourseSchedule(
    int groupId,
    int courseId,
    CourseScheduleRequestModel request,
  ) async {
    try {
      log.info('Creating CourseSchedule for Course $courseId ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesSchedulesListUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final schedule = CourseScheduleModel.fromJson(response.data);
        log.info('... CourseSchedule ${schedule.id} created for Course $courseId');
        return schedule;
      } else {
        throw ServerException(
          message: 'Failed to create course schedule',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseScheduleModel> updateCourseSchedule(
    int groupId,
    int courseId,
    int scheduleId,
    CourseScheduleRequestModel request,
  ) async {
    try {
      log.info('Updating CourseSchedule $scheduleId for Course $courseId ...');

      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesSchedulesDetailsUrl(
          groupId,
          courseId,
          scheduleId,
        ),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        log.info('... CourseSchedule $scheduleId updated');
        return CourseScheduleModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update course schedule',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }
}
