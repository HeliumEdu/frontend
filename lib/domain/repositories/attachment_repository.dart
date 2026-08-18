import 'dart:typed_data';

import 'package:heliumapp/data/models/planner/attachment_model.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentModel>> getAttachments({
    int? eventId,
    int? homeworkId,
    int? courseId,
    bool forceRefresh = false,
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
