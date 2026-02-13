// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';

abstract class RouteArgs {
  const RouteArgs();

  List<BlocProvider>? toProviders();
}

class NotificationArgs extends RouteArgs {
  final CalendarItemBloc? calendarItemBloc;
  final AttachmentBloc? attachmentBloc;

  const NotificationArgs({this.calendarItemBloc, this.attachmentBloc});

  @override
  List<BlocProvider>? toProviders() {
    if (calendarItemBloc == null && attachmentBloc == null) return null;
    return [
      if (calendarItemBloc != null)
        BlocProvider<CalendarItemBloc>.value(value: calendarItemBloc!),
      if (attachmentBloc != null)
        BlocProvider<AttachmentBloc>.value(value: attachmentBloc!),
    ];
  }
}

class ExternalCalendarsArgs extends RouteArgs {
  final ExternalCalendarBloc? externalCalendarBloc;

  const ExternalCalendarsArgs({this.externalCalendarBloc});

  @override
  List<BlocProvider>? toProviders() {
    if (externalCalendarBloc == null) return null;
    return [
      BlocProvider<ExternalCalendarBloc>.value(value: externalCalendarBloc!),
    ];
  }
}

class SettingsArgs extends RouteArgs {
  final ExternalCalendarBloc? externalCalendarBloc;

  const SettingsArgs({this.externalCalendarBloc});

  @override
  List<BlocProvider>? toProviders() {
    if (externalCalendarBloc == null) return null;
    return [
      BlocProvider<ExternalCalendarBloc>.value(value: externalCalendarBloc!),
    ];
  }
}

class CalendarItemAddArgs extends RouteArgs {
  final CalendarItemBloc calendarItemBloc;
  final AttachmentBloc attachmentBloc;
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;
  final bool isNew;

  const CalendarItemAddArgs({
    required this.calendarItemBloc,
    required this.attachmentBloc,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required this.isEdit,
    required this.isNew,
  });

  @override
  List<BlocProvider>? toProviders() {
    return [
      BlocProvider<CalendarItemBloc>.value(value: calendarItemBloc),
      BlocProvider<AttachmentBloc>.value(value: attachmentBloc),
    ];
  }
}

class CourseAddArgs extends RouteArgs {
  final CourseBloc courseBloc;
  final int courseGroupId;
  final bool isEdit;
  final bool isNew;
  final int? courseId;
  final int initialStep;

  const CourseAddArgs({
    required this.courseBloc,
    required this.courseGroupId,
    required this.isEdit,
    required this.isNew,
    this.courseId,
    this.initialStep = 0,
  });

  @override
  List<BlocProvider>? toProviders() {
    return [
      BlocProvider<CourseBloc>.value(value: courseBloc),
    ];
  }
}

class MaterialAddArgs extends RouteArgs {
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

  @override
  List<BlocProvider>? toProviders() {
    return [
      BlocProvider<MaterialBloc>.value(value: materialBloc),
    ];
  }
}
