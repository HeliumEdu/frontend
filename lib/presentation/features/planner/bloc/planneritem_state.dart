// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class PlannerItemState extends BaseState {
  PlannerItemState({required super.origin, super.message});
}

abstract class BaseEntityState extends PlannerItemState {
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

class PlannerItemInitial extends PlannerItemState {
  PlannerItemInitial({required super.origin});
}

class PlannerItemsLoading extends PlannerItemState {
  PlannerItemsLoading({required super.origin});
}

class PlannerItemsError extends PlannerItemState {
  PlannerItemsError({required super.origin, required super.message});
}

class PlannerItemScreenDataFetched extends PlannerItemState {
  final PlannerItemBaseModel? plannerItem;
  final List<CourseGroupModel> courseGroups;
  final List<CourseModel> courses;
  final List<CourseScheduleModel> courseSchedules;
  final List<CategoryModel> categories;
  final List<ResourceModel> resources;

  PlannerItemScreenDataFetched({
    required super.origin,
    required this.plannerItem,
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

class EventDeleted extends PlannerItemState {
  final int id;

  EventDeleted({required super.origin, required this.id});
}

class AllEventsDeleted extends PlannerItemState {
  AllEventsDeleted({required super.origin});
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

class HomeworkDeleted extends PlannerItemState {
  final int id;

  HomeworkDeleted({required super.origin, required this.id});
}
