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

  bool matches({int? eventId, int? homeworkId, int? courseId}) =>
      this.eventId == eventId &&
      this.homeworkId == homeworkId &&
      this.courseId == courseId;
}

class AttachmentsFetchFailed extends AttachmentsError
    with AttachmentsFetchIdentity {
  @override
  final int? eventId;
  @override
  final int? homeworkId;
  @override
  final int? courseId;

  AttachmentsFetchFailed({
    required super.message,
    this.eventId,
    this.homeworkId,
    this.courseId,
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

  AttachmentsFetched({
    required this.attachments,
    this.eventId,
    this.homeworkId,
    this.courseId,
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

  AttachmentDeleted({required this.id, this.courseId, this.eventId, this.homeworkId});
}
