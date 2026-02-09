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
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class HomeworkRemoteDataSource extends BaseDataSource {
  Future<List<HomeworkModel>> getHomeworks({
    required DateTime from,
    required DateTime to,
    List<String>? categoryTitles,
    String? search,
    String? title,
    bool? shownOnCalendar,
  });

  Future<HomeworkModel> getHomework({required int id});

  Future<HomeworkModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  });

  Future<HomeworkModel> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  });

  Future<void> deleteHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });
}

class HomeworkRemoteDataSourceImpl extends HomeworkRemoteDataSource {
  final DioClient dioClient;

  HomeworkRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<HomeworkModel>> getHomeworks({
    required DateTime from,
    required DateTime to,
    List<String>? categoryTitles,
    String? search,
    String? title,
    bool? shownOnCalendar,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'from': HeliumDateTime.formatDateForApi(from),
        'to': HeliumDateTime.formatDateForApi(to),
      };
      if (categoryTitles?.isNotEmpty ?? false) {
        final sanitizedTitles = categoryTitles
            ?.map((title) => title.trim())
            .where((title) => title.isNotEmpty)
            .toSet()
            .toList();
        if (sanitizedTitles!.isNotEmpty) {
          queryParameters['category__title_in'] = sanitizedTitles.join(',');
        }
      }
      if (search != null) queryParameters['search'] = search;
      if (title != null) queryParameters['title'] = title;
      if (shownOnCalendar != null) {
        queryParameters['shown_on_calendar'] = shownOnCalendar.toString();
      }

      _log.info('Fetching Homeworks ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerHomeworkListUrl,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          final homeworks =
              data.map((json) => HomeworkModel.fromJson(json)).toList();
          _log.info('... fetched ${homeworks.length} Homework(s)');
          return homeworks;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch homework: ${response.statusCode}',
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
  Future<HomeworkModel> getHomework({required int id}) async {
    try {
      _log.info('Fetching Homework $id ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerHomeworkListUrl,
        queryParameters: {'id': id},
      );

      if (response.statusCode == 200) {
        if (response.data.isEmpty) {
          throw NotFoundException(message: 'Homework not found');
        }
        _log.info('... Homework $id fetched');
        return HomeworkModel.fromJson(response.data[0]);
      } else {
        throw ServerException(
          message: 'Failed to fetch homework: ${response.statusCode}',
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
  Future<HomeworkModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  }) async {
    try {
      _log.info('Creating Homework for Course $courseId in CourseGroup $groupId ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesHomeworkListUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final homework = HomeworkModel.fromJson(response.data);
        _log.info('... Homework ${homework.id} created for Course $courseId');
        return homework;
      } else {
        throw ServerException(
          message: 'Failed to create homework: ${response.statusCode}',
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
  Future<HomeworkModel> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  }) async {
    try {
      _log.info('Updating Homework $homeworkId for Course $courseId ...');
      final response = await dioClient.dio.patch(
        ApiUrl.plannerCourseGroupsCoursesHomeworkDetailsUrl(
          groupId,
          courseId,
          homeworkId,
        ),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Homework $homeworkId updated');
        return HomeworkModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update homework: ${response.statusCode}',
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
  Future<void> deleteHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  }) async {
    try {
      _log.info('Deleting Homework $homeworkId for Course $courseId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesHomeworkDetailsUrl(
          groupId,
          courseId,
          homeworkId,
        ),
      );

      if (response.statusCode == 204) {
        _log.info('... Homework $homeworkId deleted');
      } else {
        throw ServerException(
          message: 'Failed to delete homework: ${response.statusCode}',
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
