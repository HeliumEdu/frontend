// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:heliumapp/data/sources/attachment_remote_data_source.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AttachmentRemoteDataSource remoteDataSource;

  AttachmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AttachmentModel>> createAttachment({
    required File file,
    int? course,
    int? event,
    int? homework,
  }) async {
    return await remoteDataSource.createAttachment(
      file: file,
      course: course,
      event: event,
      homework: homework,
    );
  }

  @override
  Future<List<AttachmentModel>> getAttachments() async {
    return await remoteDataSource.getAttachments();
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    return await remoteDataSource.deleteAttachment(attachmentId);
  }
}
