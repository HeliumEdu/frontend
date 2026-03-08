// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/grade_repository.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_event.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_state.dart';

class GradeBloc extends Bloc<GradeEvent, GradeState> {
  final GradeRepository gradeRepository;
  final CourseRepository courseRepository;

  GradeBloc({required this.gradeRepository, required this.courseRepository})
    : super(GradeInitial()) {
    on<FetchGradeScreenDataEvent>(_onFetchGrades);
  }

  Future<void> _onFetchGrades(
    FetchGradeScreenDataEvent event,
    Emitter<GradeState> emit,
  ) async {
    emit(GradesLoading());

    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(),
        gradeRepository.getGrades(),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final grades = results[1] as List<GradeCourseGroupModel>;

      emit(GradeScreenDataFetched(courseGroups: courseGroups, grades: grades));
    } on HeliumException catch (e) {
      emit(GradesError(message: e.message));
    } catch (e) {
      emit(GradesError(message: 'An unexpected error occurred.'));
    }
  }
}
