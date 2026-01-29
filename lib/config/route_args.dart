// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';

class NotificationArgs {
  final CalendarItemBloc? calendarItemBloc;

  const NotificationArgs({this.calendarItemBloc});
}

class CalendarItemAddArgs {
  final CalendarItemBloc calendarItemBloc;
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;

  const CalendarItemAddArgs({
    required this.calendarItemBloc,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required this.isEdit,
  });
}

class CalendarItemReminderArgs {
  final CalendarItemBloc calendarItemBloc;
  final bool isEvent;
  final int entityId;
  final bool isEdit;

  const CalendarItemReminderArgs({
    required this.calendarItemBloc,
    required this.isEvent,
    required this.entityId,
    required this.isEdit,
  });
}

class CalendarItemAttachmentArgs {
  final CalendarItemBloc calendarItemBloc;
  final bool isEvent;
  final int entityId;
  final bool isEdit;

  const CalendarItemAttachmentArgs({
    required this.calendarItemBloc,
    required this.isEvent,
    required this.entityId,
    required this.isEdit,
  });
}

class CourseAddArgs {
  final CourseBloc courseBloc;
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;

  const CourseAddArgs({
    required this.courseBloc,
    required this.courseGroupId,
    this.courseId,
    required this.isEdit,
  });
}

class MaterialAddArgs {
  final MaterialBloc materialBloc;
  final int materialGroupId;
  final int? materialId;
  final bool isEdit;

  const MaterialAddArgs({
    required this.materialBloc,
    required this.materialGroupId,
    this.materialId,
    required this.isEdit,
  });
}

class VerifyScreenArgs {
  final String? username;
  final String? code;

  const VerifyScreenArgs({this.username, this.code});
}
