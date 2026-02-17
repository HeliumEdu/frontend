// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';

class CourseAttachments extends BaseAttachments {
  final int courseGroupId;

  CourseAttachments({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  CourseAttachmentsContent buildContent() {
    return CourseAttachmentsContent(
      courseGroupId: courseGroupId,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class CourseAttachmentsContent extends BaseAttachmentsContent {
  final int courseGroupId;

  const CourseAttachmentsContent({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseAttachmentsState<CourseAttachmentsContent> createState() =>
      _CourseAttachmentsWidgetState();
}

class _CourseAttachmentsWidgetState
    extends BaseAttachmentsState<CourseAttachmentsContent> {
  @override
  FetchAttachmentsEvent createFetchAttachmentsEvent() {
    return FetchAttachmentsEvent(courseId: widget.entityId);
  }

  @override
  CreateAttachmentEvent createCreateAttachmentsEvent() {
    return CreateAttachmentEvent(
      files: filesToUpload,
      courseId: widget.entityId,
    );
  }
}
