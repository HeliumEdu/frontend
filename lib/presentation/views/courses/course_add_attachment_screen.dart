// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_event.dart';
import 'package:heliumapp/presentation/views/core/base_attachment_sub_screen.dart';
import 'package:heliumapp/presentation/widgets/course_add_stepper.dart';

class CourseAddAttachmentScreen extends BaseAttachmentScreen {
  final int courseGroupId;

  CourseAddAttachmentScreen({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    required super.isNew,
  });

  @override
  CourseAddAttachmentProvidedScreen buildScreen() {
    return CourseAddAttachmentProvidedScreen(
      courseGroupId: courseGroupId,
      entityId: entityId,
      isEdit: isEdit,
      isNew: isNew,
    );
  }
}

class CourseAddAttachmentProvidedScreen extends BaseAttachmentProvidedScreen {
  final int courseGroupId;

  const CourseAddAttachmentProvidedScreen({
    super.key,
    required this.courseGroupId,
    required super.entityId,
    required super.isEdit,
    required super.isNew,
  });

  @override
  BaseAttachmentScreenState<CourseAddAttachmentProvidedScreen> createState() =>
      _CourseAddAttachmentScreenState();
}

// ignore: missing_override_of_must_be_overridden
class _CourseAddAttachmentScreenState
    extends BaseAttachmentScreenState<CourseAddAttachmentProvidedScreen> {
  @override
  String get screenTitle => !widget.isNew ? 'Edit Class' : 'Add Class';

  @override
  IconData? get icon => Icons.school;

  @override
  StatelessWidget buildStepper() {
    return CourseStepper(
      selectedIndex: 3,
      courseGroupId:
          (widget as CourseAddAttachmentProvidedScreen).courseGroupId,
      courseId: widget.entityId,
      isEdit: widget.isEdit,
      isNew: widget.isNew,
    );
  }

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
