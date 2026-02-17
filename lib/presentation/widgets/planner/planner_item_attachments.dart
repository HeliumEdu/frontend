// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/presentation/bloc/attachment/attachment_event.dart';
import 'package:heliumapp/presentation/widgets/core/base_attachments.dart';

class PlannerItemAttachments extends BaseAttachments {
  final bool isEvent;

  PlannerItemAttachments({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  PlannerItemAttachmentsContent buildContent() {
    return PlannerItemAttachmentsContent(
      isEvent: isEvent,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class PlannerItemAttachmentsContent extends BaseAttachmentsContent {
  final bool isEvent;

  const PlannerItemAttachmentsContent({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseAttachmentsState<PlannerItemAttachmentsContent> createState() =>
      _PlannerItemAttachmentsWidgetState();
}

class _PlannerItemAttachmentsWidgetState
    extends BaseAttachmentsState<PlannerItemAttachmentsContent> {
  @override
  FetchAttachmentsEvent createFetchAttachmentsEvent() {
    if (widget.isEvent) {
      return FetchAttachmentsEvent(eventId: widget.entityId);
    } else {
      return FetchAttachmentsEvent(homeworkId: widget.entityId);
    }
  }

  @override
  CreateAttachmentEvent createCreateAttachmentsEvent() {
    if (widget.isEvent) {
      return CreateAttachmentEvent(
        files: filesToUpload,
        eventId: widget.entityId,
      );
    } else {
      return CreateAttachmentEvent(
        files: filesToUpload,
        homeworkId: widget.entityId,
      );
    }
  }
}
