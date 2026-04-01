// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final CourseRepository courseRepository;
  final CategoryRepository categoryRepository;
  final ResourceRepository resourceRepository;

  PlannerBloc({
    required this.courseRepository,
    required this.categoryRepository,
    required this.resourceRepository,
  }) : super(PlannerInitial(origin: EventOrigin.bloc)) {
    on<FetchPlannerScreenDataEvent>(_onFetchPlannerScreenDataEvent);
    on<SkipCourseOccurrenceEvent>(_onSkipCourseOccurrence);
  }

  Future<void> _onSkipCourseOccurrence(
    SkipCourseOccurrenceEvent event,
    Emitter<PlannerState> emit,
  ) async {
    try {
      final exceptions = [...event.course.exceptions, event.date]..sort();
      await courseRepository.updateCourseExceptions(
        event.course.courseGroup,
        event.course.id,
        exceptions,
      );
      emit(
        CourseOccurrenceSkipped(
          origin: event.origin,
          updatedCourse: event.course.copyWith(exceptions: exceptions),
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerError(origin: event.origin, message: e.displayMessage));
    } catch (e) {
      emit(
        PlannerError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onFetchPlannerScreenDataEvent(
    FetchPlannerScreenDataEvent event,
    Emitter<PlannerState> emit,
  ) async {
    emit(PlannerLoading(origin: event.origin));
    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        courseRepository.getCourses(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        categoryRepository.getCategories(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        resourceRepository.getResources(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final courses = results[1] as List<CourseModel>;
      final categories = results[2] as List<CategoryModel>;
      final resources = results[3] as List<ResourceModel>;

      emit(
        PlannerScreenDataFetched(
          origin: event.origin,
          courseGroups: courseGroups,
          courses: courses,
          categories: categories,
          resources: resources,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }
}
