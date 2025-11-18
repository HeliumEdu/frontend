import 'package:dio/dio.dart';
import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/core/network_urls.dart';
import 'package:helium_student_flutter/data/models/planner/grade_course_group_model.dart';

abstract class GradeRemoteDataSource {
  Future<List<GradeCourseGroupModel>> getGrades();
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final DioClient dioClient;

  GradeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<GradeCourseGroupModel>> getGrades() async {
    try {
      print(' Fetching grades...');

      final response = await dioClient.dio.get(NetworkUrl.gradesUrl);

      if (response.statusCode == 200) {
        print(' Grades fetched successfully!');

        // API returns: { "course_groups": [...] }
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;

          if (responseMap.containsKey('course_groups') &&
              responseMap['course_groups'] is List) {
            final grades = (responseMap['course_groups'] as List)
                .map(
                  (group) => GradeCourseGroupModel.fromJson(
                    group as Map<String, dynamic>,
                  ),
                )
                .toList();

            print(' Found ${grades.length} course group(s)');
            return grades;
          } else {
            throw ServerException(
              message: 'Invalid response format: missing course_groups',
              code: '200',
            );
          }
        } else {
          throw ServerException(
            message: 'Invalid response format: expected Map',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch grades',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (statusCode == 401) {
          return UnauthorizedException(
            message: 'Unauthorized. Please login again.',
            code: '401',
          );
        } else if (statusCode == 400) {
          String errorMessage = 'Validation error occurred.';

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                final errors = <String>[];
                responseData.forEach((key, value) {
                  if (value is List) {
                    for (var msg in value) {
                      errors.add('$key: $msg');
                    }
                  } else {
                    errors.add('$key: $value');
                  }
                });
                if (errors.isNotEmpty) {
                  errorMessage = errors.join('\n');
                }
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (e) {
              errorMessage = 'Validation error: ${responseData.toString()}';
            }
          }

          return ValidationException(
            message: errorMessage,
            code: '400',
            details: responseData,
          );
        } else if (statusCode == 500) {
          return ServerException(
            message: 'Server error. Please try again later.',
            code: '500',
          );
        } else {
          String errorMessage =
              error.response?.statusMessage ?? 'Unknown error';

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                if (responseData.containsKey('message')) {
                  errorMessage = responseData['message'].toString();
                } else if (responseData.containsKey('error')) {
                  errorMessage = responseData['error'].toString();
                } else if (responseData.containsKey('detail')) {
                  errorMessage = responseData['detail'].toString();
                } else {
                  errorMessage = responseData.toString();
                }
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (e) {
              errorMessage =
                  'Server error: ${error.response?.statusMessage ?? "Unknown error"}';
            }
          }

          return ServerException(
            message: errorMessage,
            code: statusCode.toString(),
            details: responseData,
          );
        }

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return NetworkException(
            message: 'No internet connection',
            code: 'NO_INTERNET',
          );
        }
        return NetworkException(
          message: 'Network error occurred. Please check your connection.',
          code: 'UNKNOWN',
        );

      default:
        return NetworkException(
          message: 'Network error: ${error.message}',
          code: 'NETWORK_ERROR',
        );
    }
  }
}
