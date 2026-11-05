import 'dart:typed_data';

import 'package:heliumapp/data/models/planner/attachment_model.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentModel>> getAttachments({
    int? eventId,
    int? homeworkId,
    int? courseId,
    int? resourceId,
    bool forceRefresh = false,
  });

  Future<AttachmentModel> createAttachment({
    required Uint8List bytes,
    required String filename,
    int? course,
    int? event,
    int? homework,
    int? resource,
  });

  Future<void> deleteAttachment(int attachmentId);
}
