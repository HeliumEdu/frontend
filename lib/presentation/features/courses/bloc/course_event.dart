import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class CourseEvent extends BaseEvent {
  CourseEvent({required super.origin});
}

/// Clears all course state. Dispatched on logout so per-user data does not
/// carry into the next session.
class ResetCoursesEvent extends CourseEvent {
  ResetCoursesEvent() : super(origin: EventOrigin.bloc);
}

class FetchCoursesScreenDataEvent extends CourseEvent {
  final bool forceRefresh;

  FetchCoursesScreenDataEvent({required super.origin, this.forceRefresh = false});
}

class FetchCourseScreenDataEvent extends CourseEvent {
  final int courseGroupId;
  final int? courseId;

  FetchCourseScreenDataEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class FetchCoursesEvent extends CourseEvent {
  final bool? shownOnCalendar;

  FetchCoursesEvent({required super.origin, this.shownOnCalendar});
}

class FetchCourseEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;

  FetchCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class CreateCourseGroupEvent extends CourseEvent {
  final CourseGroupRequestModel request;

  CreateCourseGroupEvent({required super.origin, required this.request});
}

class UpdateCourseGroupEvent extends CourseEvent {
  final int courseGroupId;
  final CourseGroupRequestModel request;

  UpdateCourseGroupEvent({
    required super.origin,
    required this.courseGroupId,
    required this.request,
  });
}

class DeleteCourseGroupEvent extends CourseEvent {
  final int courseGroupId;

  DeleteCourseGroupEvent({required super.origin, required this.courseGroupId});
}

class CreateCourseEvent extends CourseEvent {
  final int courseGroupId;
  final CourseRequestModel request;
  final bool advanceNavOnSuccess;

  CreateCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.request,
    this.advanceNavOnSuccess = true,
  });
}

class UpdateCourseEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final CourseRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
    this.advanceNavOnSuccess = false,
  });
}

class DeleteCourseEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;

  DeleteCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class UpdateCourseScheduleEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final int scheduleId;
  final CourseScheduleRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateCourseScheduleEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.scheduleId,
    required this.request,
    this.advanceNavOnSuccess = false,
  });
}

class FetchHasCourseSchedulesEvent extends CourseEvent {
  final bool forceRefresh;

  FetchHasCourseSchedulesEvent({
    required super.origin,
    this.forceRefresh = false,
  });
}

class FetchCourseSchedulesEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final bool forceRefresh;

  FetchCourseSchedulesEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    this.forceRefresh = false,
  });
}

class CreateCourseScheduleEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final CourseScheduleRequestModel request;

  CreateCourseScheduleEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
  });
}

class DeleteCourseScheduleEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final int scheduleId;

  DeleteCourseScheduleEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.scheduleId,
  });
}
