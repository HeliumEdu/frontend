// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/views/core/base_reminder_sub_screen.dart';
import 'package:heliumapp/presentation/widgets/calendar_item_add_stepper.dart';

class CalendarItemAddReminderScreen extends BaseReminderScreen {
  final bool isEvent;

  CalendarItemAddReminderScreen({
    super.key,
    required super.entityId,
    required super.isEdit,
    required super.isNew,
    this.isEvent = false,
  });

  @override
  CalendarItemAddReminderProvidedScreen buildScreen() {
    return CalendarItemAddReminderProvidedScreen(
      isEvent: isEvent,
      entityId: entityId,
      isEdit: isEdit,
      isNew: isNew
    );
  }
}

class CalendarItemAddReminderProvidedScreen extends BaseReminderProvidedScreen {
  final bool isEvent;

  const CalendarItemAddReminderProvidedScreen({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    required super.isNew
  });

  @override
  BaseReminderScreenState<CalendarItemAddReminderProvidedScreen>
  createState() => _CalendarItemAddReminderScreenState();
}

// ignore: missing_override_of_must_be_overridden
class _CalendarItemAddReminderScreenState
    extends BaseReminderScreenState<CalendarItemAddReminderProvidedScreen> {
  @override
  String get screenTitle => isLoading
      ? ''
      : (!widget.isNew ? 'Edit ' : 'Add ') +
            ((widget as CalendarItemAddReminderProvidedScreen).isEvent
                ? 'Event'
                : 'Assignment');

  @override
  IconData? get icon => isLoading ? null : Icons.calendar_month;

  @override
  StatelessWidget buildStepper() {
    return CalendarItemStepper(
      selectedIndex: 1,
      eventId: (widget as CalendarItemAddReminderProvidedScreen).isEvent
          ? widget.entityId
          : null,
      homeworkId: !(widget as CalendarItemAddReminderProvidedScreen).isEvent
          ? widget.entityId
          : null,
      isEdit: widget.isEdit,
      isNew: widget.isNew
    );
  }

  @override
  FetchRemindersEvent createFetchRemindersEvent() {
    if ((widget as CalendarItemAddReminderProvidedScreen).isEvent) {
      return FetchRemindersEvent(
        origin: EventOrigin.subScreen,
        eventId: widget.entityId,
      );
    } else {
      return FetchRemindersEvent(
        origin: EventOrigin.subScreen,
        homeworkId: widget.entityId,
      );
    }
  }

  @override
  ReminderRequestModel createReminderRequest(
    String message,
    int offset,
    int offsetType,
    int type,
  ) {
    if ((widget as CalendarItemAddReminderProvidedScreen).isEvent) {
      return ReminderRequestModel(
        title: message,
        message: message,
        offset: offset,
        offsetType: offsetType,
        type: type,
        sent: false,
        dismissed: false,
        event: widget.entityId,
      );
    } else {
      return ReminderRequestModel(
        title: message,
        message: message,
        offset: offset,
        offsetType: offsetType,
        type: type,
        sent: false,
        dismissed: false,
        homework: widget.entityId,
      );
    }
  }
}
