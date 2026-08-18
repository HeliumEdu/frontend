// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/attachment_file.dart';

abstract class AttachmentEvent {}

/// Clears all attachment state. Dispatched on logout so per-user data does
/// not carry into the next session.
class ResetAttachmentsEvent extends AttachmentEvent {}

class FetchAttachmentsEvent extends AttachmentEvent {
  int? eventId;
  int? homeworkId;
  int? courseId;
  bool forceRefresh;

  FetchAttachmentsEvent({this.eventId, this.homeworkId, this.courseId, this.forceRefresh = false});
}

class CreateAttachmentEvent extends AttachmentEvent {
  final List<AttachmentFile> files;
  int? eventId;
  int? homeworkId;
  int? courseId;

  CreateAttachmentEvent({
    required this.files,
    this.eventId,
    this.homeworkId,
    this.courseId,
  });
}

class DeleteAttachmentEvent extends AttachmentEvent {
  final int id;
  final int? courseId;
  final int? eventId;
  final int? homeworkId;

  DeleteAttachmentEvent({
    required this.id,
    this.courseId,
    this.eventId,
    this.homeworkId,
  });
}
