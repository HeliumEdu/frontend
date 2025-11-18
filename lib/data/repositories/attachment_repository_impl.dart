import 'dart:io';
import 'package:helium_student_flutter/data/datasources/attachment_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/attachment_model.dart';
import 'package:helium_student_flutter/domain/repositories/attachment_repository.dart';

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
