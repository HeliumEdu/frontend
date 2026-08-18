// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';

class PlannerItemAttachments extends BaseAttachments {
  final bool isEvent;

  const PlannerItemAttachments({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
    super.contentKey,
  });

  @override
  BaseAttachmentsContent buildContent() {
    return _PlannerItemAttachmentsContent(
      key: contentKey,
      isEvent: isEvent,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class _PlannerItemAttachmentsContent extends BaseAttachmentsContent {
  final bool isEvent;

  const _PlannerItemAttachmentsContent({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseAttachmentsState createState() => _PlannerItemAttachmentsWidgetState();
}

class _PlannerItemAttachmentsWidgetState extends BaseAttachmentsState {
  _PlannerItemAttachmentsContent get _typedWidget =>
      widget as _PlannerItemAttachmentsContent;

  @override
  FetchAttachmentsEvent createFetchAttachmentsEvent({bool forceRefresh = false}) {
    if (_typedWidget.isEvent) {
      return FetchAttachmentsEvent(eventId: widget.entityId, forceRefresh: forceRefresh);
    } else {
      return FetchAttachmentsEvent(homeworkId: widget.entityId, forceRefresh: forceRefresh);
    }
  }

  @override
  CreateAttachmentEvent createCreateAttachmentsEvent() {
    if (_typedWidget.isEvent) {
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
