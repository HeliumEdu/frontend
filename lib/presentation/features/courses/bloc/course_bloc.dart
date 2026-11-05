import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository courseRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final CategoryRepository categoryRepository;
  final AttachmentRepository attachmentRepository;
  final ReminderRepository reminderRepository;
  final NoteRepository noteRepository;
  final LinkedNoteSaver _linkedNoteSaver;

  CourseBloc({
    required this.courseRepository,
    required this.courseScheduleRepository,
    required this.categoryRepository,
    required this.attachmentRepository,
    required this.reminderRepository,
    required this.noteRepository,
  }) : _linkedNoteSaver = LinkedNoteSaver(noteRepository),
       super(CourseInitial(origin: EventOrigin.bloc)) {
    on<FetchCoursesScreenDataEvent>(_onFetchCoursesScreenDataEvent);
    on<FetchCourseScreenDataEvent>(_onFetchCourseScreenDataEvent);
    on<CreateCourseGroupEvent>(_onCreateCourseGroup);
    on<UpdateCourseGroupEvent>(_onUpdateCourseGroup);
    on<DeleteCourseGroupEvent>(_onDeleteCourseGroup);
    on<CreateCourseEvent>(_onCreateCourse);
    on<UpdateCourseEvent>(_onUpdateCourse);
    on<DeleteCourseEvent>(_onDeleteCourse);
    on<UpdateCourseScheduleEvent>(_onUpdateCourseSchedule);
    on<UpdateCourseGroupExceptionsEvent>(_onUpdateCourseGroupExceptions);
    on<UpdateCourseExceptionsEvent>(_onUpdateCourseExceptions);
    on<FetchHasCourseSchedulesEvent>(_onFetchHasCourseSchedules);
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
    if (!event.passive) emit(CoursesLoading(origin: event.origin));
    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(forceRefresh: event.forceRefresh),
        courseRepository.getCourses(forceRefresh: event.forceRefresh),
        categoryRepository.getCategories(forceRefresh: event.forceRefresh),
        attachmentRepository.getAttachments(forceRefresh: event.forceRefresh),
        reminderRepository.getReminders(sent: false, forceRefresh: event.forceRefresh),
        noteRepository.getNotes(
          linkedEntityType: 'course',
          includeContent: true,
          forceRefresh: event.forceRefresh,
        ),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final courses = results[1] as List<CourseModel>;
      final categories = results[2] as List<CategoryModel>;
      final attachments = results[3] as List<AttachmentModel>;
      final reminders = results[4] as List<ReminderModel>;
      final notes = results[5] as List<NoteModel>;

      emit(
        CoursesScreenDataFetched(
          origin: event.origin,
          courseGroups: courseGroups,
          courses: courses,
          categories: categories,
          attachments: attachments,
          reminders: reminders,
          notes: notes,
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
          courseRepository.getCourse(
            event.courseGroupId,
            event.courseId!,
            forceRefresh: event.forceRefresh,
          ),
        if (event.courseId != null)
          noteRepository.getNotes(
            linkedEntityType: 'course',
            courseId: event.courseId,
            includeContent: true,
            forceRefresh: event.forceRefresh,
          ),
      ]);
      final courseGroup = results[0] as CourseGroupModel;
      CourseModel? course;
      NoteModel? linkedNote;

      if (event.courseId != null) {
        course = results[1] as CourseModel;
        final notes = results[2] as List<NoteModel>;
        linkedNote = notes.isNotEmpty ? notes.first : null;
      }
      emit(
        CourseScreenDataFetched(
          origin: event.origin,
          courseGroup: courseGroup,
          course: course,
          linkedNote: linkedNote,
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

  Future<void> _onFetchHasCourseSchedules(
    FetchHasCourseSchedulesEvent event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final hasCourseSchedules = await courseScheduleRepository
          .hasCourseSchedules(
            shownOnCalendar: true,
            forceRefresh: event.forceRefresh,
          );
      emit(
        HasCourseSchedulesFetched(
          origin: event.origin,
          hasCourseSchedules: hasCourseSchedules,
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

  Future<void> _onFetchCourseSchedules(
    FetchCourseSchedulesEvent event,
    Emitter<CourseState> emit,
  ) async {
    if (!event.passive) emit(CoursesLoading(origin: event.origin));
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
        version: event.version,
      );
      emit(CourseGroupUpdated(origin: event.origin, courseGroup: courseGroup));
    } on ConflictException catch (e) {
      emit(CourseGroupConflict(
        origin: event.origin,
        latest: CourseGroupModel.fromJson(e.latest),
      ));
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
      final linkedNoteSave = await _linkedNoteSaver.saveForNewEntity(
        event.noteContent,
        courseId: course.id,
      );

      emit(
        CourseCreated(
          origin: event.origin,
          course: course,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteSave.noteId,
          linkedNoteSave: linkedNoteSave,
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
      final saved = await _linkedNoteSaver.saveWithEntity(
        courseRepository.updateCourse(
          event.courseGroupId,
          event.courseId,
          event.request,
          version: event.version,
        ),
        event.linkedNote,
        courseId: event.courseId,
      );
      final conflict = saved.entityConflict;
      if (conflict != null) {
        emit(CourseConflict(
          origin: event.origin,
          latest: CourseModel.fromJson(conflict.latest),
          linkedNoteSave: saved.note,
        ));
        return;
      }
      if (saved.entityFailure case final failure?) {
        emit(CoursesError(
          origin: event.origin,
          message: failure.message,
          linkedNoteSave: saved.note,
        ));
        return;
      }
      emit(
        CourseUpdated(
          origin: event.origin,
          course: saved.entity!,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: saved.note!.noteId,
          linkedNoteSave: saved.note,
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
        version: event.version,
      );
      emit(
        CourseScheduleUpdated(
          origin: event.origin,
          schedule: schedule,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
        ),
      );
    } on ConflictException catch (e) {
      emit(CourseScheduleConflict(
        origin: event.origin,
        latest: CourseScheduleModel.fromJson(e.latest),
      ));
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

  Future<void> _onUpdateCourseGroupExceptions(
    UpdateCourseGroupExceptionsEvent event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final courseGroup = await courseRepository.updateCourseGroupExceptions(
        event.courseGroupId,
        event.exceptions,
      );
      emit(CourseGroupExceptionsUpdated(
        origin: event.origin,
        courseGroup: courseGroup,
      ));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.displayMessage));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onUpdateCourseExceptions(
    UpdateCourseExceptionsEvent event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final course = await courseRepository.updateCourseExceptions(
        event.courseGroupId,
        event.courseId,
        event.exceptions,
      );
      emit(CourseExceptionsUpdated(origin: event.origin, course: course));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.displayMessage));
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
