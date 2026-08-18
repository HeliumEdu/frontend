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
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getAttachments(
      eventId: eventId,
      homeworkId: homeworkId,
      courseId: courseId,
      forceRefresh: forceRefresh,
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
    return remoteDataSource.createAttachment(
      bytes: bytes,
      filename: filename,
      event: event,
      homework: homework,
      course: course,
    );
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    return remoteDataSource.deleteAttachment(attachmentId);
  }
}
