import 'package:dio/dio.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/core/network_urls.dart';
import 'package:heliumedu/data/models/planner/homework_request_model.dart';
import 'package:heliumedu/data/models/planner/homework_response_model.dart';

abstract class HomeworkRemoteDataSource {
  Future<List<HomeworkResponseModel>> getAllHomework({
    List<String>? categoryTitles,
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

      final filterSummary =
          queryParameters.containsKey('category__title_in')
              ? " with categories: ${queryParameters['category__title_in']}"
              : '';
      print('📚 Fetching all homework$filterSummary...');
      final response = await dioClient.dio.get(
        NetworkUrl.allHomeworkUrl,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          print('✅ Fetched ${data.length} homework(s)');
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
      print('❌ Error fetching all homework: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<HomeworkResponseModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  }) async {
    try {
      print('📝 Creating homework for course: $courseId in group: $groupId');
      final response = await dioClient.dio.post(
        NetworkUrl.homeworkUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Homework created successfully');
        return HomeworkResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Error creating homework: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<HomeworkResponseModel>> getHomework({
    required int groupId,
    required int courseId,
  }) async {
    try {
      print('📚 Fetching homework for course: $courseId');
      final response = await dioClient.dio.get(
        NetworkUrl.homeworkUrl(groupId, courseId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('✅ Fetched ${data.length} homework(s)');
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
      throw AppException(message: 'Unexpected error occurred: $e');
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
        NetworkUrl.homeworkByIdUrl(groupId, courseId, homeworkId),
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
      throw AppException(message: 'Unexpected error occurred: $e');
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
        NetworkUrl.homeworkByIdUrl(groupId, courseId, homeworkId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        print('✅ Homework updated successfully');
        return HomeworkResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
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
        NetworkUrl.homeworkByIdUrl(groupId, courseId, homeworkId),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Homework deleted successfully');
      } else {
        throw ServerException(
          message: 'Failed to delete homework: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }
}
