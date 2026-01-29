// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/event_request_model.dart';
import 'package:heliumapp/data/models/planner/homework_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';

abstract class CalendarItemEvent extends BaseEvent {
  CalendarItemEvent({required super.origin});
}

class FetchCalendarItemScreenDataEvent extends CalendarItemEvent {
  final int? eventId;
  final int? homeworkId;

  FetchCalendarItemScreenDataEvent({
    required super.origin,
    this.eventId,
    this.homeworkId,
  });
}

class FetchEventEvent extends CalendarItemEvent {
  final int eventId;

  FetchEventEvent({required super.origin, required this.eventId});
}

class CreateEventEvent extends CalendarItemEvent {
  final EventRequestModel request;
  final bool advanceNavOnSuccess;

  CreateEventEvent({
    required super.origin,
    required this.request,
    this.advanceNavOnSuccess = true,
  });
}

class UpdateEventEvent extends CalendarItemEvent {
  final int id;
  final EventRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateEventEvent({
    required super.origin,
    required this.id,
    required this.request,
    this.advanceNavOnSuccess = true,
  });
}

class DeleteEventEvent extends CalendarItemEvent {
  final int id;

  DeleteEventEvent({required super.origin, required this.id});
}

class FetchHomeworkEvent extends CalendarItemEvent {
  final int id;

  FetchHomeworkEvent({required super.origin, required this.id});
}

class CreateHomeworkEvent extends CalendarItemEvent {
  final int courseGroupId;
  final int courseId;
  final HomeworkRequestModel request;
  final bool advanceNavOnSuccess;

  CreateHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
    this.advanceNavOnSuccess = true,
  });
}

class UpdateHomeworkEvent extends CalendarItemEvent {
  final int courseGroupId;
  final int courseId;
  final int homeworkId;
  final HomeworkRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.homeworkId,
    required this.request,
    this.advanceNavOnSuccess = true,
  });
}

class DeleteHomeworkEvent extends CalendarItemEvent {
  final int courseGroupId;
  final int courseId;
  final int homeworkId;

  DeleteHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.homeworkId,
  });
}
