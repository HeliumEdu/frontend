// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/category_request_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository courseRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final CategoryRepository categoryRepository;

  CourseBloc({
    required this.courseRepository,
    required this.courseScheduleRepository,
    required this.categoryRepository,
  }) : super(CourseInitial(origin: EventOrigin.bloc)) {
    on<FetchCoursesScreenDataEvent>(_onFetchCoursesScreenDataEvent);
    on<FetchCourseScreenDataEvent>(_onFetchCourseScreenDataEvent);
    on<FetchCoursesEvent>(_onFetchCourses);
    on<FetchCourseEvent>(_onFetchCourse);
    on<FetchCourseScheduleEvent>(_onFetchCourseSchedule);
    on<FetchAllCourseSchedulesEventsEvent>(_onFetchAllCourseScheduleEvents);
    on<CreateCourseGroupEvent>(_onCreateCourseGroup);
    on<UpdateCourseGroupEvent>(_onUpdateCourseGroup);
    on<DeleteCourseGroupEvent>(_onDeleteCourseGroup);
    on<CreateCourseEvent>(_onCreateCourse);
    on<UpdateCourseEvent>(_onUpdateCourse);
    on<DeleteCourseEvent>(_onDeleteCourse);
    on<UpdateCourseScheduleEvent>(_onUpdateCourseSchedule);
  }

  Future<void> _onFetchCoursesScreenDataEvent(
    FetchCoursesScreenDataEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));
    try {
      final courseGroups = await courseRepository.getCourseGroups();
      final courses = await courseRepository.getCourses();
      emit(
        CoursesScreenDataFetched(
          origin: event.origin,
          courseGroups: courseGroups,
          courses: courses,
        ),
      );
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
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
      final courseGroup = await courseRepository.getCourseGroup(
        event.courseGroupId,
      );
      final CourseModel? course;
      if (event.courseId != null) {
        course = await courseRepository.getCourse(
          event.courseGroupId,
          event.courseId!,
        );
      } else {
        course = null;
      }
      emit(
        CourseScreenDataFetched(
          origin: event.origin,
          courseGroup: courseGroup,
          course: course,
        ),
      );
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchCourseSchedule(
    FetchCourseScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));

    try {
      final schedule = await courseScheduleRepository
          .getCourseScheduleForCourse(event.courseGroupId, event.courseId);
      emit(CourseScheduleFetched(origin: event.origin, schedule: schedule));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchAllCourseScheduleEvents(
    FetchAllCourseSchedulesEventsEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CoursesLoading(origin: event.origin));
    try {
      final events = await courseScheduleRepository.getCourseScheduleEvents(
        courses: event.courses,
        from: event.from,
        to: event.to,
      );

      emit(CourseScheduleEventsFetched(origin: event.origin, events: events));
    } on HeliumException catch (e) {
      emit(CoursesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CoursesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
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
        event.request,
      );

      const defaultStart = TimeOfDay(hour: 12, minute: 0);
      const defaultEnd = TimeOfDay(hour: 12, minute: 50);
      final createEmptyCourseScheduleRequest = CourseScheduleRequestModel(
        daysOfWeek: '0000000',
        sunStartTime: defaultStart,
        sunEndTime: defaultEnd,
        monStartTime: defaultStart,
        monEndTime: defaultEnd,
        tueStartTime: defaultStart,
        tueEndTime: defaultEnd,
        wedStartTime: defaultStart,
        wedEndTime: defaultEnd,
        thuStartTime: defaultStart,
        thuEndTime: defaultEnd,
        friStartTime: defaultStart,
        friEndTime: defaultEnd,
        satStartTime: defaultStart,
        satEndTime: defaultEnd,
      );

      await courseScheduleRepository.createCourseSchedule(
        course.courseGroup,
        course.id,
        createEmptyCourseScheduleRequest,
      );

      final createCategoryRequest1 = CategoryRequestModel(
        title: 'Homework 👨🏽‍💻',
        weight: '0',
        color: '#E21D55',
      );
      final createCategoryRequest2 = CategoryRequestModel(
        title: 'Final Exam 📈',
        weight: '0',
        color: '#AF4F23',
      );
      final createCategoryRequest3 = CategoryRequestModel(
        title: 'Midterm 📈',
        weight: '0',
        color: '#A17430',
      );
      final createCategoryRequest4 = CategoryRequestModel(
        title: 'Project 🔨',
        weight: '0',
        color: '#05CC90',
      );
      final createCategoryRequest5 = CategoryRequestModel(
        title: 'Quiz 💡',
        weight: '0',
        color: '#0D0E38',
      );
      final createCategoryRequest6 = CategoryRequestModel(
        title: 'Reading 📖',
        weight: '0',
        color: '#3C1534',
      );
      final createCategoryRequest7 = CategoryRequestModel(
        title: 'Lab 🧪',
        weight: '0',
        color: '#553555',
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest1,
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest2,
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest3,
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest4,
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest5,
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest6,
      );
      await categoryRepository.createCategory(
        course.courseGroup,
        course.id,
        createCategoryRequest7,
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
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
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
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}
