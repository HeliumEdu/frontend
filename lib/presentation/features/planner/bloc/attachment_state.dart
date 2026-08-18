// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

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

class AttachmentsFetched extends AttachmentState {
  final List<AttachmentModel> attachments;

  AttachmentsFetched({required this.attachments});
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
