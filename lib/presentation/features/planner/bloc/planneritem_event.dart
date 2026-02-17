// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class PlannerItemEvent extends BaseEvent {
  PlannerItemEvent({required super.origin});
}

class FetchPlannerItemScreenDataEvent extends PlannerItemEvent {
  final int? eventId;
  final int? homeworkId;

  FetchPlannerItemScreenDataEvent({
    required super.origin,
    this.eventId,
    this.homeworkId,
  });
}

class FetchEventEvent extends PlannerItemEvent {
  final int eventId;

  FetchEventEvent({required super.origin, required this.eventId});
}

class CreateEventEvent extends PlannerItemEvent {
  final EventRequestModel request;
  final bool advanceNavOnSuccess;
  final bool isClone;

  CreateEventEvent({
    required super.origin,
    required this.request,
    this.advanceNavOnSuccess = true,
    this.isClone = false,
  });
}

class UpdateEventEvent extends PlannerItemEvent {
  final int id;
  final EventRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateEventEvent({
    required super.origin,
    required this.id,
    required this.request,
    this.advanceNavOnSuccess = false,
  });
}

class DeleteEventEvent extends PlannerItemEvent {
  final int id;

  DeleteEventEvent({required super.origin, required this.id});
}

class FetchHomeworkEvent extends PlannerItemEvent {
  final int id;

  FetchHomeworkEvent({required super.origin, required this.id});
}

class CreateHomeworkEvent extends PlannerItemEvent {
  final int courseGroupId;
  final int courseId;
  final HomeworkRequestModel request;
  final bool advanceNavOnSuccess;
  final bool isClone;

  CreateHomeworkEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
    this.advanceNavOnSuccess = true,
    this.isClone = false,
  });
}

class UpdateHomeworkEvent extends PlannerItemEvent {
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
    this.advanceNavOnSuccess = false,
  });
}

class DeleteHomeworkEvent extends PlannerItemEvent {
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
