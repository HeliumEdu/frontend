// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/attachment_model.dart';

abstract class AttachmentState {
  final String? message;

  AttachmentState({this.message});
}

class AttachmentInitial extends AttachmentState {}

class AttachmentsLoading extends AttachmentState {}

class AttachmentsError extends AttachmentState {
  AttachmentsError({required super.message});
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
