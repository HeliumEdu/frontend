import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository courseRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final CategoryRepository categoryRepository;
  final AttachmentRepository attachmentRepository;
  final ReminderRepository reminderRepository;

  CourseBloc({
    required this.courseRepository,
    required this.courseScheduleRepository,
    required this.categoryRepository,
    required this.attachmentRepository,
    required this.reminderRepository,
  }) : super(CourseInitial(origin: EventOrigin.bloc)) {
    on<FetchCoursesScreenDataEvent>(_onFetchCoursesScreenDataEvent);
    on<FetchCourseScreenDataEvent>(_onFetchCourseScreenDataEvent);
    on<FetchCoursesEvent>(_onFetchCourses);
    on<FetchCourseEvent>(_onFetchCourse);
    on<CreateCourseGroupEvent>(_onCreateCourseGroup);
    on<UpdateCourseGroupEvent>(_onUpdateCourseGroup);
    on<DeleteCourseGroupEvent>(_onDeleteCourseGroup);
    on<CreateCourseEvent>(_onCreateCourse);
    on<UpdateCourseEvent>(_onUpdateCourse);
    on<DeleteCourseEvent>(_onDeleteCourse);
    on<UpdateCourseScheduleEvent>(_onUpdateCourseSchedule);
    on<FetchCourseSchedulesEvent>(_onFetchCourseSchedules);
    on<CreateCourseScheduleEvent>(_onCreateCourseSchedule);
    on<DeleteCourseScheduleEvent>(_onDeleteCourseSchedule);
    on<ResetCoursesEvent>(
      (event, emit) => emit(CourseInitial(origin: EventOrigin.bloc)),
    );
  }

  Future<void> _onFetchCoursesScreenDataEvent(
    FetchCoursesScreenDataEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));
    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(forceRefresh: event.forceRefresh),
        courseRepository.getCourses(forceRefresh: event.forceRefresh),
        categoryRepository.getCategories(forceRefresh: event.forceRefresh),
        attachmentRepository.getAttachments(forceRefresh: event.forceRefresh),
        reminderRepository.getReminders(sent: false, forceRefresh: event.forceRefresh),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final courses = results[1] as List<CourseModel>;
      final categories = results[2] as List<CategoryModel>;
      final attachments = results[3] as List<AttachmentModel>;
      final reminders = results[4] as List<ReminderModel>;

      emit(
        CoursesScreenDataFetched(
          origin: event.origin,
          courseGroups: courseGroups,
          courses: courses,
          categories: categories,
          attachments: attachments,
          reminders: reminders,
        ),
      );
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onFetchCourseScreenDataEvent(
    FetchCourseScreenDataEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final results = await Future.wait([
        courseRepository.getCourseGroup(event.courseGroupId),
        if (event.courseId != null)
          courseRepository.getCourse(event.courseGroupId, event.courseId!),
      ]);
      final courseGroup = results[0] as CourseGroupModel;
      final CourseModel? course =
          event.courseId != null ? results[1] as CourseModel : null;
      emit(
        CourseScreenDataFetched(
          origin: event.origin,
          courseGroup: courseGroup,
          course: course,
          courseGroupId: event.courseGroupId,
          courseId: event.courseId,
        ),
      );
    } on HeliumException catch (e) {
      emit(
        CourseScreenDataFailed(
          origin: event.origin,
          message: e.message,
          courseGroupId: event.courseGroupId,
          courseId: event.courseId,
        ),
      );
    } catch (e) {
      emit(
        CourseScreenDataFailed(
          origin: event.origin,
          message: HeliumException.unexpectedError,
          courseGroupId: event.courseGroupId,
          courseId: event.courseId,
        ),
      );
    }
  }

  Future<void> _onFetchCourses(
    FetchCoursesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final courses = await courseRepository.getCourses(
        shownOnCalendar: event.shownOnCalendar,
      );
      emit(CoursesFetched(origin: event.origin, courses: courses));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onFetchCourse(
    FetchCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final course = await courseRepository.getCourse(
        event.courseGroupId,
        event.courseId,
      );
      emit(CourseFetched(origin: event.origin, course: course));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onFetchCourseSchedules(
    FetchCourseSchedulesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));
    try {
      final schedules = await courseScheduleRepository
          .getCourseSchedulesForCourse(
            event.courseGroupId,
            event.courseId,
            forceRefresh: event.forceRefresh,
          );
      emit(CourseSchedulesFetched(origin: event.origin, schedules: schedules));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onCreateCourseSchedule(
    CreateCourseScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final schedule = await courseScheduleRepository.createCourseSchedule(
        event.courseGroupId,
        event.courseId,
        event.request,
      );
      emit(CourseScheduleCreated(origin: event.origin, schedule: schedule));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onDeleteCourseSchedule(
    DeleteCourseScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    try {
      await courseScheduleRepository.deleteCourseSchedule(
        event.courseGroupId,
        event.courseId,
        event.scheduleId,
      );
      emit(CourseScheduleDeleted(origin: event.origin, id: event.scheduleId));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onCreateCourseGroup(
    CreateCourseGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final courseGroup = await courseRepository.createCourseGroup(
        event.request,
      );
      emit(CourseGroupCreated(origin: event.origin, courseGroup: courseGroup));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onUpdateCourseGroup(
    UpdateCourseGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final courseGroup = await courseRepository.updateCourseGroup(
        event.courseGroupId,
        event.request,
      );
      emit(CourseGroupUpdated(origin: event.origin, courseGroup: courseGroup));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onDeleteCourseGroup(
    DeleteCourseGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      await courseRepository.deleteCourseGroup(event.courseGroupId);
      emit(CourseGroupDeleted(origin: event.origin, id: event.courseGroupId));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onCreateCourse(
    CreateCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final course = await courseRepository.createCourse(
        event.courseGroupId,
        event.request.copyWith(template: CourseTemplate.standard.value),
      );

      emit(
        CourseCreated(
          origin: event.origin,
          course: course,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
        ),
      );
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onUpdateCourse(
    UpdateCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final course = await courseRepository.updateCourse(
        event.courseGroupId,
        event.courseId,
        event.request,
      );
      emit(
        CourseUpdated(
          origin: event.origin,
          course: course,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
        ),
      );
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onDeleteCourse(
    DeleteCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      await courseRepository.deleteCourse(event.courseGroupId, event.courseId);
      emit(CourseDeleted(origin: event.origin, id: event.courseId));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onUpdateCourseSchedule(
    UpdateCourseScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final schedule = await courseScheduleRepository.updateCourseSchedule(
        event.courseGroupId,
        event.courseId,
        event.scheduleId,
        event.request,
      );
      emit(
        CourseScheduleUpdated(
          origin: event.origin,
          schedule: schedule,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
        ),
      );
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }
}
