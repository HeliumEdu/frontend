// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/sources/attachment_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AttachmentRemoteDataSource remoteDataSource;

  AttachmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AttachmentModel>> getAttachments({
    int? eventId,
    int? homeworkId,
    int? courseId,
  }) async {
    return await remoteDataSource.getAttachments(
      eventId: eventId,
      homeworkId: homeworkId,
      courseId: courseId,
    );
  }

  @override
  Future<AttachmentModel> createAttachment({
    required Uint8List bytes,
    required String filename,
    int? event,
    int? homework,
    int? course,
  }) async {
    return await remoteDataSource.createAttachment(
      bytes: bytes,
      filename: filename,
      event: event,
      homework: homework,
      course: course,
    );
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    return await remoteDataSource.deleteAttachment(attachmentId);
  }
}
