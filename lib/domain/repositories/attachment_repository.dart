import 'dart:io';
import 'package:heliumedu/data/models/planner/attachment_model.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentModel>> createAttachment({
    required File file,
    int? course,
    int? event,
    int? homework,
  });

  Future<List<AttachmentModel>> getAttachments();
  Future<void> deleteAttachment(int attachmentId);
}
