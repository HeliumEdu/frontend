import 'package:heliumapp/data/models/attachment_file.dart';

abstract class AttachmentEvent {}

/// Clears all attachment state. Dispatched on logout so per-user data does
/// not carry into the next session.
class ResetAttachmentsEvent extends AttachmentEvent {}

class FetchAttachmentsEvent extends AttachmentEvent {
  int? eventId;
  int? homeworkId;
  int? courseId;
  int? resourceId;
  bool forceRefresh;

  FetchAttachmentsEvent({
    this.eventId,
    this.homeworkId,
    this.courseId,
    this.resourceId,
    this.forceRefresh = false,
  });
}

class CreateAttachmentEvent extends AttachmentEvent {
  final List<AttachmentFile> files;
  int? eventId;
  int? homeworkId;
  int? courseId;
  int? resourceId;

  CreateAttachmentEvent({
    required this.files,
    this.eventId,
    this.homeworkId,
    this.courseId,
    this.resourceId,
  });
}

class DeleteAttachmentEvent extends AttachmentEvent {
  final int id;
  final int? courseId;
  final int? eventId;
  final int? homeworkId;
  final int? resourceId;

  DeleteAttachmentEvent({
    required this.id,
    this.courseId,
    this.eventId,
    this.homeworkId,
    this.resourceId,
  });
}
