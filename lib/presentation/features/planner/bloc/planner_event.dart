import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class PlannerEvent extends BaseEvent {
  PlannerEvent({required super.origin});
}

class FetchPlannerScreenDataEvent extends PlannerEvent {
  final bool forceRefresh;
  final bool background;

  FetchPlannerScreenDataEvent({
    required super.origin,
    this.forceRefresh = false,
    this.background = false,
  });
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

class SkipCourseScheduleOccurrenceEvent extends PlannerEvent {
  final CourseModel course;
  final CourseScheduleModel schedule;
  final DateTime date;

  SkipCourseScheduleOccurrenceEvent({
    required super.origin,
    required this.course,
    required this.schedule,
    required this.date,
  });
}
