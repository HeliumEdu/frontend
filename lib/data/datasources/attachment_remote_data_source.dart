// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/core/network_urls.dart';
import 'package:heliumedu/data/models/planner/attachment_model.dart';

abstract class AttachmentRemoteDataSource {
  Future<List<AttachmentModel>> createAttachment({
    required File file,
    int? course,
    int? event,
    int? homework,
  });

  Future<List<AttachmentModel>> getAttachments();

  Future<void> deleteAttachment(int attachmentId);
}

class AttachmentRemoteDataSourceImpl implements AttachmentRemoteDataSource {
  final DioClient dioClient;

  AttachmentRemoteDataSourceImpl({required this.dioClient});

  AppException _handleDioError(DioException e) {
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
        return ServerException(message: 'Attachment not found');
      } else if (statusCode == 413) {
        return ValidationException(message: 'File size exceeds 10mb limit');
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
  Future<List<AttachmentModel>> createAttachment({
    required File file,
    int? course,
    int? event,
    int? homework,
  }) async {
    try {
      print('📎 Creating attachment: ${file.path}');

      // Validate that at least one of course, event, or homework is provided
      if (course == null && event == null && homework == null) {
        throw ValidationException(
          message: 'At least one of class, event, or homework must be provided',
        );
      }

      // Check file size (max 10mb)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw ValidationException(message: 'File size exceeds 10mb limit');
      }

      // Create FormData for file upload
      final multipart = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );

      // Per API docs, the file field must be 'file[]' (can accept multiple)
      final formData = FormData.fromMap({
        'file[]': multipart,
        if (course != null) 'course': course,
        if (event != null) 'event': event,
        if (homework != null) 'homework': homework,
      });

      final response = await dioClient.dio.post(
        NetworkUrl.attachmentsUrl,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Attachment created successfully');
        // API returns a list even for single file upload
        final List<dynamic> data = response.data is List
            ? response.data
            : [response.data];
        return data.map((json) => AttachmentModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to create attachment: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Error creating attachment: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      print('❌ Unexpected error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<AttachmentModel>> getAttachments() async {
    try {
      final response = await dioClient.dio.get(NetworkUrl.attachmentsUrl);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AttachmentModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch attachments: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    try {
      final response = await dioClient.dio.delete(
        NetworkUrl.deleteAttachmentUrl(attachmentId),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Attachment deleted successfully');
      } else {
        throw ServerException(
          message: 'Failed to delete attachment: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }
}
