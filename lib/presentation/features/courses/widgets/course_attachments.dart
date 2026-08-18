// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';

class CourseAttachments extends BaseAttachments {
  final int courseGroupId;

  const CourseAttachments({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
    super.contentKey,
  });

  @override
  BaseAttachmentsContent buildContent() {
    return _CourseAttachmentsContent(
      key: contentKey,
      courseGroupId: courseGroupId,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class _CourseAttachmentsContent extends BaseAttachmentsContent {
  final int courseGroupId;

  const _CourseAttachmentsContent({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseAttachmentsState createState() => _CourseAttachmentsWidgetState();
}

class _CourseAttachmentsWidgetState extends BaseAttachmentsState {
  @override
  FetchAttachmentsEvent createFetchAttachmentsEvent({bool forceRefresh = false}) {
    return FetchAttachmentsEvent(courseId: widget.entityId, forceRefresh: forceRefresh);
  }

  @override
  CreateAttachmentEvent createCreateAttachmentsEvent() {
    return CreateAttachmentEvent(
      files: filesToUpload,
      courseId: widget.entityId,
    );
  }
}
