import 'package:heliumapp/data/models/planner/attachment_model.dart';

abstract class AttachmentState {
  final String? message;

  AttachmentState({this.message});
}

class AttachmentInitial extends AttachmentState {}

class AttachmentsLoading extends AttachmentState {}

class AttachmentsError extends AttachmentState {
  final Set<String> failedFilenames;

  AttachmentsError({required super.message, this.failedFilenames = const {}});
}

mixin AttachmentsFetchIdentity {
  int? get eventId;

  int? get homeworkId;

  int? get courseId;

  int? get resourceId;

  bool matches({int? eventId, int? homeworkId, int? courseId, int? resourceId}) =>
      this.eventId == eventId &&
      this.homeworkId == homeworkId &&
      this.courseId == courseId &&
      this.resourceId == resourceId;
}

class AttachmentsFetchFailed extends AttachmentsError
    with AttachmentsFetchIdentity {
  @override
  final int? eventId;
  @override
  final int? homeworkId;
  @override
  final int? courseId;
  @override
  final int? resourceId;

  AttachmentsFetchFailed({
    required super.message,
    this.eventId,
    this.homeworkId,
    this.courseId,
    this.resourceId,
  });
}

class AttachmentsFetched extends AttachmentState with AttachmentsFetchIdentity {
  final List<AttachmentModel> attachments;
  @override
  final int? eventId;
  @override
  final int? homeworkId;
  @override
  final int? courseId;
  @override
  final int? resourceId;

  AttachmentsFetched({
    required this.attachments,
    this.eventId,
    this.homeworkId,
    this.courseId,
    this.resourceId,
  });
}

class AttachmentsCreated extends AttachmentState {
  final List<AttachmentModel> attachments;

  AttachmentsCreated({required this.attachments});
}

class AttachmentDeleted extends AttachmentState {
  final int id;
  final int? courseId;
  final int? eventId;
  final int? homeworkId;
  final int? resourceId;

  AttachmentDeleted({
    required this.id,
    this.courseId,
    this.eventId,
    this.homeworkId,
    this.resourceId,
  });
}
