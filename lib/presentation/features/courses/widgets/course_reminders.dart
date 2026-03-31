// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_reminders.dart';

class CourseReminders extends BaseReminders {
  CourseReminders({
    super.key,
    required super.entityId,
    required super.isEdit,
    super.userSettings,
    super.headerTitle,
  });

  @override
  BaseRemindersContent buildContent() {
    return _CourseRemindersContent(
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
      headerTitle: headerTitle,
    );
  }
}

class _CourseRemindersContent extends BaseRemindersContent {
  const _CourseRemindersContent({
    required super.entityId,
    required super.isEdit,
    super.userSettings,
    super.headerTitle,
  });

  @override
  BaseReminderWidgetState<_CourseRemindersContent> createState() =>
      _CourseRemindersState();
}

class _CourseRemindersState
    extends BaseReminderWidgetState<_CourseRemindersContent> {
  @override
  FetchRemindersEvent createFetchRemindersEvent() {
    return FetchRemindersEvent(
      origin: EventOrigin.subScreen,
      courseId: widget.entityId,
    );
  }

  @override
  ReminderRequestModel createReminderRequest(
    String message,
    int offset,
    int offsetType,
    int type,
  ) {
    return ReminderRequestModel(
      title: message,
      message: message,
      offset: offset,
      offsetType: offsetType,
      type: type,
      sent: false,
      dismissed: false,
      course: widget.entityId,
    );
  }
}
