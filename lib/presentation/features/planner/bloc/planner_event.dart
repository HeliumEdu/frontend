// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class PlannerEvent extends BaseEvent {
  PlannerEvent({required super.origin});
}

class FetchPlannerScreenDataEvent extends PlannerEvent {
  FetchPlannerScreenDataEvent({required super.origin});
}

class SkipCourseOccurrenceEvent extends PlannerEvent {
  final CourseModel course;
  final DateTime date;

  SkipCourseOccurrenceEvent({
    required super.origin,
    required this.course,
    required this.date,
  });
}
