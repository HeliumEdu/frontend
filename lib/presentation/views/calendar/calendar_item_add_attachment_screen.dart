// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_event.dart';
import 'package:heliumapp/presentation/views/core/base_attachment_sub_screen.dart';
import 'package:heliumapp/presentation/widgets/calendar_item_add_stepper.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class CalendarItemAddAttachmentScreen extends BaseAttachmentScreen {
  final bool isEvent;

  CalendarItemAddAttachmentScreen({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
  });

  @override
  CalendarItemAddAttachmentProvidedScreen buildScreen() {
    return CalendarItemAddAttachmentProvidedScreen(
      isEvent: isEvent,
      entityId: entityId,
      isEdit: isEdit,
    );
  }
}

class CalendarItemAddAttachmentProvidedScreen
    extends BaseAttachmentProvidedScreen {
  final bool isEvent;

  const CalendarItemAddAttachmentProvidedScreen({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
  });

  @override
  BaseAttachmentScreenState<CalendarItemAddAttachmentProvidedScreen>
  createState() => _CalendarItemAddAttachmentScreenState();
}

// ignore: missing_override_of_must_be_overridden
class _CalendarItemAddAttachmentScreenState
    extends BaseAttachmentScreenState<CalendarItemAddAttachmentProvidedScreen> {
  @override
  String get screenTitle => isLoading
      ? ''
      : (widget.isEdit ? 'Edit ' : 'Add ') +
            ((widget as CalendarItemAddAttachmentProvidedScreen).isEvent
                ? 'Event'
                : 'Assignment');

  @override
  StatelessWidget buildStepper() {
    return CalendarItemStepper(
      selectedIndex: 2,
      eventId: (widget as CalendarItemAddAttachmentProvidedScreen).isEvent
          ? widget.entityId
          : null,
      homeworkId: !(widget as CalendarItemAddAttachmentProvidedScreen).isEvent
          ? widget.entityId
          : null,
      isEdit: widget.isEdit,
    );
  }

  @override
  FetchAttachmentsEvent createFetchAttachmentsEvent() {
    if ((widget as CalendarItemAddAttachmentProvidedScreen).isEvent) {
      return FetchAttachmentsEvent(eventId: widget.entityId);
    } else {
      return FetchAttachmentsEvent(homeworkId: widget.entityId);
    }
  }

  @override
  CreateAttachmentEvent createCreateAttachmentsEvent() {
    if ((widget as CalendarItemAddAttachmentProvidedScreen).isEvent) {
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
