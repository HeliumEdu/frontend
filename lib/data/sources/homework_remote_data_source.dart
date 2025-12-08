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
import 'package:heliumapp/data/models/planner/homework_request_model.dart';
import 'package:heliumapp/data/models/planner/homework_response_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class HomeworkRemoteDataSource {
  Future<List<HomeworkResponseModel>> getAllHomework({
    List<String>? categoryTitles,
    String? from,
    String? to,
    String? ordering,
    String? search,
    String? title,
  });

  Future<HomeworkResponseModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  });

  Future<List<HomeworkResponseModel>> getHomework({
    required int groupId,
    required int courseId,
  });

  Future<HomeworkResponseModel> getHomeworkById({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });

  Future<HomeworkResponseModel> updateHomework({
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

class HomeworkRemoteDataSourceImpl implements HomeworkRemoteDataSource {
  final DioClient dioClient;

  HomeworkRemoteDataSourceImpl({required this.dioClient});

  HeliumException _handleDioError(DioException e) {
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
        return ServerException(message: 'Homework not found');
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
  Future<List<HomeworkResponseModel>> getAllHomework({
    List<String>? categoryTitles,
    String? from,
    String? to,
    String? ordering,
    String? search,
    String? title,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (categoryTitles != null && categoryTitles.isNotEmpty) {
        final sanitizedTitles = categoryTitles
            .map((title) => title.trim())
            .where((title) => title.isNotEmpty)
            .toSet()
            .toList();
        if (sanitizedTitles.isNotEmpty) {
          queryParameters['category__title_in'] = sanitizedTitles.join(',');
        }
      }
      if (from != null) queryParameters['from'] = from;
      if (to != null) queryParameters['to'] = to;
      if (ordering != null) queryParameters['ordering'] = ordering;
      if (search != null) queryParameters['search'] = search;
      if (title != null) queryParameters['title'] = title;

      final filterSummary = queryParameters.containsKey('category__title_in')
          ? " with categories: ${queryParameters['category__title_in']}"
          : '';
      log.info('📚 Fetching all homework $filterSummary...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerHomeworkListUrl,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          log.info('✅ Fetched ${data.length} homework(s)');
          return data
              .map((json) => HomeworkResponseModel.fromJson(json))
              .toList();
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
    } on DioException catch (e) {
      log.info('❌ Error fetching all homework: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<HomeworkResponseModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  }) async {
    try {
      log.info('📝 Creating homework for course: $courseId in group: $groupId');
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesHomeworkListUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log.info('✅ Homework created successfully');
        return HomeworkResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      log.info('❌ Error creating homework: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<HomeworkResponseModel>> getHomework({
    required int groupId,
    required int courseId,
  }) async {
    try {
      log.info('📚 Fetching homework for course: $courseId');
      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesHomeworkListUrl(groupId, courseId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        log.info('✅ Fetched ${data.length} homework(s)');
        return data
            .map((json) => HomeworkResponseModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<HomeworkResponseModel> getHomeworkById({
    required int groupId,
    required int courseId,
    required int homeworkId,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.plannerHomeworkListUrl,
        queryParameters: {'id': homeworkId},
      );

      if (response.statusCode == 200) {
        return HomeworkResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<HomeworkResponseModel> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  }) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesHomeworkDetailsUrl(
          groupId,
          courseId,
          homeworkId,
        ),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        log.info('✅ Homework updated successfully');
        return HomeworkResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  }) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesHomeworkDetailsUrl(
          groupId,
          courseId,
          homeworkId,
        ),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        log.info('✅ Homework deleted successfully');
      } else {
        throw ServerException(
          message: 'Failed to delete homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }
}
