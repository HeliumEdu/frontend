// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_state.dart';

abstract class CalendarItemState extends BaseState {
  CalendarItemState({required super.origin, super.message});
}

abstract class BaseEntityState extends CalendarItemState {
  final int entityId;
  final bool isEvent;
  final bool advanceNavOnSuccess;

  BaseEntityState({
    required super.origin,
    required this.entityId,
    required this.isEvent,
    required this.advanceNavOnSuccess,
  });
}

abstract class HomeworkEntityState extends BaseEntityState {
  final HomeworkModel homework;

  HomeworkEntityState({
    required super.origin,
    required this.homework,
    required super.entityId,
    required super.isEvent,
    required super.advanceNavOnSuccess,
  });
}

abstract class EventEntityState extends BaseEntityState {
  final EventModel event;

  EventEntityState({
    required super.origin,
    required this.event,
    required super.entityId,
    required super.isEvent,
    required super.advanceNavOnSuccess,
  });
}

class CalendarItemInitial extends CalendarItemState {
  CalendarItemInitial({required super.origin});
}

class CalendarItemsLoading extends CalendarItemState {
  CalendarItemsLoading({required super.origin});
}

class CalendarItemsError extends CalendarItemState {
  CalendarItemsError({required super.origin, required super.message});
}

class CalendarItemsFetched extends CalendarItemState {
  final List<EventModel> events;
  final List<HomeworkModel> homeworks;
  final List<CourseScheduleEventModel> courseScheduleEvents;
  final List<ExternalCalendarEventModel> externalCalendarEvents;

  CalendarItemsFetched({
    required super.origin,
    required this.events,
    required this.homeworks,
    required this.courseScheduleEvents,
    required this.externalCalendarEvents,
  });
}

class CalendarItemScreenDataFetched extends CalendarItemState {
  final CalendarItemBaseModel? calendarItem;
  final List<CourseGroupModel> courseGroups;
  final List<CourseModel> courses;
  final List<CourseScheduleModel> courseSchedules;
  final List<CategoryModel> categories;
  final List<ResourceModel> resources;

  CalendarItemScreenDataFetched({
    required super.origin,
    required this.calendarItem,
    required this.courseGroups,
    required this.courses,
    required this.courseSchedules,
    required this.categories,
    required this.resources,
  });
}

class EventFetched extends EventEntityState {
  EventFetched({
    required super.origin,
    required super.event,
    required super.entityId,
    required super.isEvent,
    super.advanceNavOnSuccess = true,
  });
}

class EventCreated extends EventEntityState {
  final bool isClone;

  EventCreated({
    required super.origin,
    required super.event,
    required super.entityId,
    required super.isEvent,
    required super.advanceNavOnSuccess,
    this.isClone = false,
  });
}

class EventUpdated extends EventEntityState {
  EventUpdated({
    required super.origin,
    required super.event,
    required super.entityId,
    required super.isEvent,
    required super.advanceNavOnSuccess,
  });
}

class EventDeleted extends CalendarItemState {
  final int id;

  EventDeleted({required super.origin, required this.id});
}

class HomeworkFetched extends HomeworkEntityState {
  HomeworkFetched({
    required super.origin,
    required super.homework,
    required super.entityId,
    required super.isEvent,
    super.advanceNavOnSuccess = true,
  });
}

class HomeworkCreated extends HomeworkEntityState {
  final bool isClone;

  HomeworkCreated({
    required super.origin,
    required super.homework,
    required super.entityId,
    required super.isEvent,
    required super.advanceNavOnSuccess,
    this.isClone = false,
  });
}

class HomeworkUpdated extends HomeworkEntityState {
  HomeworkUpdated({
    required super.origin,
    required super.homework,
    required super.entityId,
    required super.isEvent,
    required super.advanceNavOnSuccess,
  });
}

class HomeworkDeleted extends CalendarItemState {
  final int id;

  HomeworkDeleted({required super.origin, required this.id});
}
