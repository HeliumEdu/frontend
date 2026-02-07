// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

import 'package:heliumapp/data/models/planner/attachment_model.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentModel>> getAttachments({
    int? eventId,
    int? homeworkId,
    int? courseId,
  });

  Future<AttachmentModel> createAttachment({
    required Uint8List bytes,
    required String filename,
    int? course,
    int? event,
    int? homework,
  });

  Future<void> deleteAttachment(int attachmentId);
}
