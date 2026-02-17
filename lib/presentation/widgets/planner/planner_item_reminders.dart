// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/widgets/core/base_reminders.dart';

class PlannerItemReminders extends BaseReminders {
  final bool isEvent;

  PlannerItemReminders({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  PlannerItemRemindersContent buildContent() {
    return PlannerItemRemindersContent(
      isEvent: isEvent,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
    );
  }
}

class PlannerItemRemindersContent extends BaseRemindersContent {
  final bool isEvent;

  const PlannerItemRemindersContent({
    super.key,
    required this.isEvent,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
  });

  @override
  BaseReminderWidgetState<PlannerItemRemindersContent> createState() =>
      _PlannerItemRemindersState();
}

class _PlannerItemRemindersState
    extends BaseReminderWidgetState<PlannerItemRemindersContent> {
  @override
  FetchRemindersEvent createFetchRemindersEvent() {
    if (widget.isEvent) {
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
    if (widget.isEvent) {
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
