// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/presentation/bloc/attachment/attachment_event.dart';
import 'package:heliumapp/presentation/widgets/base_attachment_widget.dart';

class CourseAttachmentsWidget extends BaseAttachmentWidget {
  final int courseGroupId;

  CourseAttachmentsWidget({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  CourseAttachmentsWidgetContent buildContent() {
    return CourseAttachmentsWidgetContent(
      courseGroupId: courseGroupId,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class CourseAttachmentsWidgetContent extends BaseAttachmentWidgetContent {
  final int courseGroupId;

  const CourseAttachmentsWidgetContent({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseAttachmentWidgetState<CourseAttachmentsWidgetContent> createState() =>
      _CourseAttachmentsWidgetState();
}

class _CourseAttachmentsWidgetState
    extends BaseAttachmentWidgetState<CourseAttachmentsWidgetContent> {
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
