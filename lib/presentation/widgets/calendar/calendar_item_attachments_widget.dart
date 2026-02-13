// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/presentation/bloc/attachment/attachment_event.dart';
import 'package:heliumapp/presentation/widgets/base_attachment_widget.dart';

class CalendarItemAttachmentsWidget extends BaseAttachmentWidget {
  final bool isEvent;

  CalendarItemAttachmentsWidget({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  CalendarItemAttachmentsWidgetContent buildContent() {
    return CalendarItemAttachmentsWidgetContent(
      isEvent: isEvent,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class CalendarItemAttachmentsWidgetContent extends BaseAttachmentWidgetContent {
  final bool isEvent;

  const CalendarItemAttachmentsWidgetContent({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseAttachmentWidgetState<CalendarItemAttachmentsWidgetContent> createState() =>
      _CalendarItemAttachmentsWidgetState();
}

class _CalendarItemAttachmentsWidgetState
    extends BaseAttachmentWidgetState<CalendarItemAttachmentsWidgetContent> {
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
