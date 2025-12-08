// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_group_response_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses();

  Future<List<CourseModel>> getCoursesByGroupId(int groupId);

  Future<CourseModel> getCourseById(int groupId, int courseId);

  Future<CourseModel> createCourse(CourseRequestModel request);

  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  );

  Future<void> deleteCourse(int groupId, int courseId);

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

  Future<CourseScheduleModel> getCourseScheduleById(
    int groupId,
    int courseId,
    int scheduleId,
  );

  Future<List<CategoryModel>> getCategoriesByCourse(int groupId, int courseId);

  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  );

  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  );

  Future<void> deleteCategory(int groupId, int courseId, int categoryId);

  Future<List<AttachmentModel>> uploadAttachments({
    required List<File> files,
    int? courseId,
    int? eventId,
    int? homeworkId,
  });

  Future<List<AttachmentModel>> getAttachments({
    int? courseId,
    int? eventId,
    int? homeworkId,
  });

  Future<void> deleteAttachment(int attachmentId);

  Future<List<CourseGroupResponseModel>> getCourseGroups();

  Future<CourseGroupResponseModel> createCourseGroup(
    CourseGroupRequestModel request,
  );

  Future<CourseGroupResponseModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  );

  Future<void> deleteCourseGroup(int groupId);
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final DioClient dioClient;

  CourseRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await dioClient.dio.get(ApiUrl.plannerCoursesListUrl);

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((course) => CourseModel.fromJson(course))
              .toList();
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
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<CourseModel>> getCoursesByGroupId(int groupId) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesListUrl(groupId),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((course) => CourseModel.fromJson(course))
              .toList();
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
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseModel> getCourseById(int groupId, int courseId) async {
    try {
      log.info(' Fetching course details...');
      log.info('  Group ID: $groupId');
      log.info('  Course ID: $courseId');

      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesDetailsUrl(groupId, courseId),
      );

      if (response.statusCode == 200) {
        log.info(' Course details fetched successfully!');
        return CourseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch course details',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseModel> createCourse(CourseRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesListUrl(request.courseGroup),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CourseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create course',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  ) async {
    try {
      log.info('🔄 Updating course...');
      log.info('  Group ID: $groupId');
      log.info('  Course ID: $courseId');

      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesDetailsUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.info('✅ Course updated successfully!');
        return CourseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update course',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteCourse(int groupId, int courseId) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesDetailsUrl(groupId, courseId),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        // Successfully deleted
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete course',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseScheduleModel> createCourseSchedule(
    int groupId,
    int courseId,
    CourseScheduleRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesSchedulesListUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CourseScheduleModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create course schedule',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
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
      log.info('🔄 Updating course schedule...');
      log.info('  Group ID: $groupId');
      log.info('  Course ID: $courseId');
      log.info('  Schedule ID: $scheduleId');

      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesSchedulesDetailsUrl(groupId, courseId, scheduleId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.info('✅ Course schedule updated successfully!');
        return CourseScheduleModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update course schedule',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseScheduleModel> getCourseScheduleById(
    int groupId,
    int courseId,
    int scheduleId,
  ) async {
    try {
      log.info('📅 Fetching schedule details...');
      log.info('  Group ID: $groupId');
      log.info('  Course ID: $courseId');
      log.info('  Schedule ID: $scheduleId');

      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesSchedulesDetailsUrl(groupId, courseId, scheduleId),
      );

      if (response.statusCode == 200) {
        log.info('✅ Schedule details fetched successfully!');
        return CourseScheduleModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch schedule details',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategoriesByCourse(
    int groupId,
    int courseId,
  ) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.plannerCourseGroupsCoursesCategoriesListUrl(groupId, courseId),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((category) => CategoryModel.fromJson(category))
              .toList();
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch categories',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesCategoriesListUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CategoryModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create category',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  ) async {
    try {
      log.info(' Updating category...');
      log.info('  Group ID: $groupId');
      log.info('  Course ID: $courseId');
      log.info('  Category ID: $categoryId');

      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesCategoriesDetailsUrl(groupId, courseId, categoryId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.info(' Category updated successfully!');
        return CategoryModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update category',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteCategory(int groupId, int courseId, int categoryId) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesCategoriesDetailsUrl(groupId, courseId, categoryId),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete category',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<AttachmentModel>> uploadAttachments({
    required List<File> files,
    int? courseId,
    int? eventId,
    int? homeworkId,
  }) async {
    try {
      log.info(' Starting file upload...');
      log.info(' Files to upload: ${files.length}');

      // Prepare multipart files
      List<MultipartFile> multipartFiles = [];
      for (var file in files) {
        final fileName = file.path.split('/').last;
        final fileSize = file.lengthSync();
        log.info('  - $fileName ($fileSize bytes)');

        multipartFiles.add(
          await MultipartFile.fromFile(file.path, filename: fileName),
        );
      }

      // Build form data
      final formData = FormData();

      // Add files - API expects 'file[]' field for multiple files
      // Each file uses the same field name 'file[]' to create an array
      for (var multipartFile in multipartFiles) {
        formData.files.add(MapEntry('file[]', multipartFile));
      }

      // Add at least one of: course, event, or homework
      if (courseId != null) {
        formData.fields.add(MapEntry('course', courseId.toString()));
        log.info('🔗 Attached to course: $courseId');
      }
      if (eventId != null) {
        formData.fields.add(MapEntry('event', eventId.toString()));
        log.info('🔗 Attached to event: $eventId');
      }
      if (homeworkId != null) {
        formData.fields.add(MapEntry('homework', homeworkId.toString()));
        log.info('🔗 Attached to homework: $homeworkId');
      }

      log.info('🚀 Sending multipart/form-data request...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerAttachmentsListUrl,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      log.info('✅ Upload successful! Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Response is always a list, even for single file
        if (response.data is List) {
          return (response.data as List)
              .map((attachment) => AttachmentModel.fromJson(attachment))
              .toList();
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to upload attachments',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<AttachmentModel>> getAttachments({
    int? courseId,
    int? eventId,
    int? homeworkId,
  }) async {
    try {
      log.info('📥 Fetching attachments...');

      // Build query parameters
      Map<String, dynamic> queryParams = {};
      if (courseId != null) {
        queryParams['course'] = courseId;
        log.info('🔗 Fetching attachments for course: $courseId');
      }
      if (eventId != null) {
        queryParams['event'] = eventId;
        log.info('🔗 Fetching attachments for event: $eventId');
      }
      if (homeworkId != null) {
        queryParams['homework'] = homeworkId;
        log.info('🔗 Fetching attachments for homework: $homeworkId');
      }

      final response = await dioClient.dio.get(
        ApiUrl.plannerAttachmentsListUrl,
        queryParameters: queryParams,
      );

      log.info('✅ Attachments fetched! Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          final attachments = (response.data as List)
              .map((attachment) => AttachmentModel.fromJson(attachment))
              .toList();
          log.info('📎 Found ${attachments.length} attachment(s)');
          return attachments;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch attachments',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    try {
      log.info('🗑️ Deleting attachment: $attachmentId');

      final response = await dioClient.dio.delete(
        ApiUrl.plannerAttachmentsDetailsUrl(attachmentId),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        log.info('✅ Attachment deleted successfully!');
      } else {
        throw ServerException(
          message: 'Failed to delete attachment',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<CourseGroupResponseModel>> getCourseGroups() async {
    try {
      final response = await dioClient.dio.get(ApiUrl.plannerCourseGroupsListUrl);

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((group) => CourseGroupResponseModel.fromJson(group))
              .toList();
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
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseGroupResponseModel> createCourseGroup(
    CourseGroupRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CourseGroupResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create course group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<CourseGroupResponseModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsDetailsUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return CourseGroupResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update course group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteCourseGroup(int groupId) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesListUrl(groupId)
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete course group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  HeliumException _handleDioError(DioException error) {
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
          // Try to extract error message from response
          String errorMessage =
              error.response?.statusMessage ?? 'Unknown error';

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                // Look for common error message keys
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
