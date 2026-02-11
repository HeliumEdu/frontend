// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/attachment_file.dart';

abstract class AttachmentEvent {}

class FetchAttachmentsEvent extends AttachmentEvent {
  int? eventId;
  int? homeworkId;
  int? courseId;

  FetchAttachmentsEvent({this.eventId, this.homeworkId, this.courseId});
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
