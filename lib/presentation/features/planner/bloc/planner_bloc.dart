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
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_state.dart';

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final CourseRepository courseRepository;
  final CategoryRepository categoryRepository;

  PlannerBloc({
    required this.courseRepository,
    required this.categoryRepository,
  }) : super(PlannerInitial()) {
    on<FetchPlannerScreenDataEvent>(_onFetchPlannerScreenDataEvent);
  }

  Future<void> _onFetchPlannerScreenDataEvent(
    FetchPlannerScreenDataEvent event,
    Emitter<PlannerState> emit,
  ) async {
    emit(PlannerLoading());
    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(shownOnCalendar: true),
        courseRepository.getCourses(shownOnCalendar: true),
        categoryRepository.getCategories(shownOnCalendar: true),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final courses = results[1] as List<CourseModel>;
      final categories = results[2] as List<CategoryModel>;

      emit(PlannerScreenDataFetched(courseGroups: courseGroups, courses: courses, categories: categories));
    } on HeliumException catch (e) {
      emit(PlannerError(message: e.message));
    } catch (e) {
      emit(PlannerError(message: 'An unexpected error occurred: $e'));
    }
  }
}
