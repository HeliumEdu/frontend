// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:nested/nested.dart';

class NotificationArgs {
  final List<SingleChildWidget>? providers;

  const NotificationArgs({this.providers});
}

class CalendarItemAddArgs {
  final CalendarItemBloc calendarItemBloc;
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;
  final bool isNew;

  const CalendarItemAddArgs({
    required this.calendarItemBloc,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required this.isEdit,
    required this.isNew,
  });
}

class CalendarItemReminderArgs {
  final CalendarItemBloc calendarItemBloc;
  final bool isEvent;
  final int entityId;
  final bool isEdit;
  final bool isNew;

  const CalendarItemReminderArgs({
    required this.calendarItemBloc,
    required this.isEvent,
    required this.entityId,
    required this.isEdit,
    required this.isNew,
  });
}

class CalendarItemAttachmentArgs {
  final CalendarItemBloc calendarItemBloc;
  final bool isEvent;
  final int entityId;
  final bool isEdit;
  final bool isNew;

  const CalendarItemAttachmentArgs({
    required this.calendarItemBloc,
    required this.isEvent,
    required this.entityId,
    required this.isEdit,
    required this.isNew,
  });
}

class CourseAddArgs {
  final CourseBloc courseBloc;
  final int courseGroupId;
  final bool isEdit;
  final bool isNew;
  final int? courseId;

  const CourseAddArgs({
    required this.courseBloc,
    required this.courseGroupId,
    required this.isEdit,
    required this.isNew,
    this.courseId,
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
