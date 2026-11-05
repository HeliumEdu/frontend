import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class CourseState extends BaseState {
  CourseState({required super.origin, super.message});
}

abstract class CourseGroupEntityState extends CourseState {
  final CourseGroupModel courseGroup;

  CourseGroupEntityState({required super.origin, required this.courseGroup});
}

abstract class CourseEntityState extends CourseState {
  final CourseModel course;
  final bool advanceNavOnSuccess;

  CourseEntityState({
    required super.origin,
    required this.course,
    required this.advanceNavOnSuccess,
  });
}

class CourseInitial extends CourseState {
  CourseInitial({required super.origin});
}

class CoursesLoading extends CourseState {
  CoursesLoading({required super.origin});
}

class CoursesError extends CourseState {
  final LinkedNoteSave? linkedNoteSave;

  CoursesError({
    required super.origin,
    required super.message,
    this.linkedNoteSave,
  });
}

class CoursesScreenDataFetched extends CourseState {
  final List<CourseGroupModel> courseGroups;
  final List<CourseModel> courses;
  final List<CategoryModel> categories;
  final List<AttachmentModel> attachments;
  final List<ReminderModel> reminders;
  final List<NoteModel> notes;

  CoursesScreenDataFetched({
    required super.origin,
    super.message,
    required this.courseGroups,
    required this.courses,
    required this.categories,
    required this.attachments,
    required this.reminders,
    required this.notes,
  });
}

mixin CourseScreenDataIdentity {
  int get courseGroupId;

  int? get courseId;

  bool matches({required int courseGroupId, int? courseId}) =>
      this.courseGroupId == courseGroupId && this.courseId == courseId;
}

class CourseScreenDataFailed extends CoursesError
    with CourseScreenDataIdentity {
  @override
  final int courseGroupId;
  @override
  final int? courseId;

  CourseScreenDataFailed({
    required super.origin,
    required super.message,
    required this.courseGroupId,
    this.courseId,
  });
}

class CourseScreenDataFetched extends CourseState with CourseScreenDataIdentity {
  final CourseGroupModel courseGroup;
  final CourseModel? course;
  final NoteModel? linkedNote;
  @override
  final int courseGroupId;
  @override
  final int? courseId;

  CourseScreenDataFetched({
    required super.origin,
    required this.courseGroup,
    required this.courseGroupId,
    this.course,
    this.linkedNote,
    this.courseId,
  });
}

class CourseGroupCreated extends CourseGroupEntityState {
  CourseGroupCreated({required super.origin, required super.courseGroup});
}

class CourseGroupUpdated extends CourseGroupEntityState {
  CourseGroupUpdated({required super.origin, required super.courseGroup});
}

class CourseGroupDeleted extends CourseState {
  final int id;

  CourseGroupDeleted({required super.origin, required this.id});
}

class CourseCreated extends CourseEntityState {
  final bool redirectToNotebook;
  final int? linkedNoteId;
  final LinkedNoteSave? linkedNoteSave;

  CourseCreated({
    required super.origin,
    required super.course,
    required super.advanceNavOnSuccess,
    this.redirectToNotebook = false,
    this.linkedNoteId,
    this.linkedNoteSave,
  });
}

class CourseUpdated extends CourseEntityState {
  final bool redirectToNotebook;
  final int? linkedNoteId;
  final LinkedNoteSave? linkedNoteSave;

  CourseUpdated({
    required super.origin,
    required super.course,
    required super.advanceNavOnSuccess,
    this.redirectToNotebook = false,
    this.linkedNoteId,
    this.linkedNoteSave,
  });
}

class CourseDeleted extends CourseState {
  final int id;

  CourseDeleted({required super.origin, required this.id});
}

class CourseScheduleUpdated extends CourseState {
  final CourseScheduleModel schedule;
  final bool advanceNavOnSuccess;

  CourseScheduleUpdated({
    required super.origin,
    required this.schedule,
    required this.advanceNavOnSuccess,
  });
}

class HasCourseSchedulesFetched extends CourseState {
  final bool hasCourseSchedules;

  HasCourseSchedulesFetched({
    required super.origin,
    required this.hasCourseSchedules,
  });
}

class CourseSchedulesFetched extends CourseState {
  final List<CourseScheduleModel> schedules;

  CourseSchedulesFetched({required super.origin, required this.schedules});
}

class CourseScheduleCreated extends CourseState {
  final CourseScheduleModel schedule;

  CourseScheduleCreated({required super.origin, required this.schedule});
}

class CourseScheduleDeleted extends CourseState {
  final int id;

  CourseScheduleDeleted({required super.origin, required this.id});
}

class CourseGroupExceptionsUpdated extends CourseState {
  final CourseGroupModel courseGroup;

  CourseGroupExceptionsUpdated({required super.origin, required this.courseGroup});
}

class CourseExceptionsUpdated extends CourseState {
  final CourseModel course;

  CourseExceptionsUpdated({required super.origin, required this.course});
}

class CourseGroupConflict extends CourseState {
  final CourseGroupModel latest;

  CourseGroupConflict({required super.origin, required this.latest});
}

class CourseConflict extends CourseState {
  final CourseModel latest;
  final LinkedNoteSave? linkedNoteSave;

  CourseConflict({
    required super.origin,
    required this.latest,
    this.linkedNoteSave,
  });
}

class CourseScheduleConflict extends CourseState {
  final CourseScheduleModel latest;

  CourseScheduleConflict({required super.origin, required this.latest});
}
