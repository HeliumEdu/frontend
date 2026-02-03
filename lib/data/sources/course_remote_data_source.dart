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
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class CourseRemoteDataSource extends BaseDataSource {
  Future<List<CourseGroupModel>> getCourseGroups({bool? shownOnCalendar});

  Future<CourseGroupModel> getCourseGroup(int id);

  Future<CourseGroupModel> createCourseGroup(CourseGroupRequestModel request);

  Future<CourseGroupModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  );

  Future<void> deleteCourseGroup(int groupId);

  Future<List<CourseModel>> getCourses({int? groupId, bool? shownOnCalendar});

  Future<CourseModel> getCourse(int groupId, int courseId);

  Future<CourseModel> createCourse(int groupId, CourseRequestModel request);

  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  );

  Future<void> deleteCourse(int groupId, int courseId);
}

class CourseRemoteDataSourceImpl extends CourseRemoteDataSource {
  final DioClient dioClient;

  CourseRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CourseModel>> getCourses({
    int? groupId,
    bool? shownOnCalendar,
  }) async {
    try {
      final filterInfo = groupId != null ? ' for CourseGroup $groupId' : '';
      _log.info('Fetching Courses$filterInfo ...');

      final Map<String, dynamic> queryParameters = {};
      if (groupId != null) queryParameters['course_group'] = groupId;
      if (shownOnCalendar != null) {
        queryParameters['shown_on_calendar'] = shownOnCalendar;
      }

      final response = await dioClient.dio.get(
        ApiUrl.plannerCoursesListUrl,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final courses = (response.data as List)
              .map((course) => CourseModel.fromJson(course))
              .toList();
          _log.info('... fetched ${courses.length} Course(s)');
          return courses;
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
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseModel> getCourse(int groupId, int courseId) async {
    try {
      _log.info('Fetching Course $courseId in CourseGroup $groupId ...');

      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesDetailsUrl(groupId, courseId),
      );

      if (response.statusCode == 200) {
        _log.info('... Course $courseId fetched');
        return CourseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch course details',
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
  Future<CourseModel> createCourse(
    int groupId,
    CourseRequestModel request,
  ) async {
    try {
      _log.info('Creating Course in CourseGroup $groupId ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesListUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final course = CourseModel.fromJson(response.data);
        _log.info('... Course ${course.id} created in CourseGroup $groupId');
        return course;
      } else {
        throw ServerException(
          message: 'Failed to create course',
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
  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  ) async {
    try {
      _log.info('Updating Course $courseId in CourseGroup $groupId ...');

      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesDetailsUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Course $courseId updated');
        return CourseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update course',
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
  Future<void> deleteCourse(int groupId, int courseId) async {
    try {
      _log.info('Deleting Course $courseId in CourseGroup $groupId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesDetailsUrl(groupId, courseId),
      );

      if (response.statusCode == 204) {
        _log.info('... Course $courseId deleted');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete course',
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
  Future<List<CourseGroupModel>> getCourseGroups({
    bool? shownOnCalendar,
  }) async {
    try {
      _log.info('Fetching CourseGroups ...');

      final Map<String, dynamic> queryParameters = {};
      if (shownOnCalendar != null) {
        queryParameters['shown_on_calendar'] = shownOnCalendar;
      }

      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsListUrl,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final groups = (response.data as List)
              .map((group) => CourseGroupModel.fromJson(group))
              .toList();
          _log.info('... fetched ${groups.length} CourseGroup(s)');
          return groups;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch course groups',
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
  Future<CourseGroupModel> getCourseGroup(int id) async {
    try {
      _log.info('Fetching CourseGroup $id ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsDetailsUrl(id),
      );

      if (response.statusCode == 200) {
        _log.info('... CourseGroup $id fetched');
        return CourseGroupModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch course group',
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
  Future<CourseGroupModel> createCourseGroup(
    CourseGroupRequestModel request,
  ) async {
    try {
      _log.info('Creating CourseGroup ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final group = CourseGroupModel.fromJson(response.data);
        _log.info('... CourseGroup ${group.id} created');
        return group;
      } else {
        throw ServerException(
          message: 'Failed to create course group',
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
  Future<CourseGroupModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  ) async {
    try {
      _log.info('Updating CourseGroup $groupId ...');
      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsDetailsUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... CourseGroup $groupId updated');
        return CourseGroupModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update course group',
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
  Future<void> deleteCourseGroup(int groupId) async {
    try {
      _log.info('Deleting CourseGroup $groupId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsDetailsUrl(groupId),
      );

      if (response.statusCode == 204) {
        _log.info('... CourseGroup $groupId deleted');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete course group',
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
}
