// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class AttachmentRemoteDataSource extends BaseDataSource {
  Future<List<AttachmentModel>> getAttachments({
    int? eventId,
    int? homeworkId,
    int? courseId,
  });

  Future<AttachmentModel> createAttachment({
    required Uint8List bytes,
    required String filename,
    int? event,
    int? homework,
    int? course,
  });

  Future<void> deleteAttachment(int attachmentId);
}

class AttachmentRemoteDataSourceImpl extends AttachmentRemoteDataSource {
  final DioClient dioClient;

  AttachmentRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AttachmentModel> createAttachment({
    required Uint8List bytes,
    required String filename,
    int? event,
    int? homework,
    int? course,
  }) async {
    try {
      final fileSizeKb = (bytes.length / 1024).toStringAsFixed(1);
      final parentInfo = event != null
          ? 'Event $event'
          : homework != null
              ? 'Homework $homework'
              : course != null
                  ? 'Course $course'
                  : 'unknown';
      _log.info('Creating Attachment "$filename" (${fileSizeKb}KB) for $parentInfo ...');

      // Create FormData for file upload
      final multipart = MultipartFile.fromBytes(
        bytes,
        filename: filename,
      );

      final formData = FormData.fromMap({
        'file[]': multipart,
        'course': ?course,
        'event': ?event,
        'homework': ?homework,
      });

      final response = await dioClient.dio.post(
        ApiUrl.plannerAttachmentsListUrl,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201) {
        if (response.data.isEmpty) {
          throw ValidationException(message: 'Attachment not found in response');
        }

        final attachment = AttachmentModel.fromJson(response.data[0]);
        _log.info('... Attachment ${attachment.id} created');
        await dioClient.cacheService.invalidateAll();

        return attachment;
      } else {
        throw ServerException(
          message: 'Failed to create attachment: ${response.statusCode}',
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
  Future<List<AttachmentModel>> getAttachments({
    int? eventId,
    int? homeworkId,
    int? courseId,
  }) async {
    try {
      final parentInfo = eventId != null
          ? 'Event $eventId'
          : homeworkId != null
              ? 'Homework $homeworkId'
              : courseId != null
                  ? 'Course $courseId'
                  : 'all';
      _log.info('Fetching Attachments for $parentInfo ...');

      final Map<String, dynamic> queryParameters = {};
      if (homeworkId != null) queryParameters['homework'] = homeworkId;
      if (eventId != null) queryParameters['event'] = eventId;
      if (courseId != null) queryParameters['course'] = courseId;

      final response = await dioClient.dio.get(
        ApiUrl.plannerAttachmentsListUrl,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final attachments =
            data.map((json) => AttachmentModel.fromJson(json)).toList();
        _log.info('... fetched ${attachments.length} Attachment(s)');
        return attachments;
      } else {
        throw ServerException(
          message: 'Failed to fetch attachments: ${response.statusCode}',
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
  Future<void> deleteAttachment(int attachmentId) async {
    try {
      _log.info('Deleting Attachment $attachmentId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerAttachmentsDetailsUrl(attachmentId),
      );

      if (response.statusCode == 204) {
        _log.info('... Attachment $attachmentId deleted');
        await dioClient.cacheService.invalidateAll();
      } else {
        throw ServerException(
          message: 'Failed to delete attachment: ${response.statusCode}',
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
