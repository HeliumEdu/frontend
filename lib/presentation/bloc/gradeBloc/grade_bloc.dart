// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/domain/repositories/grade_repository.dart';
import 'package:heliumedu/presentation/bloc/gradeBloc/grade_event.dart';
import 'package:heliumedu/presentation/bloc/gradeBloc/grade_state.dart';

class GradeBloc extends Bloc<GradeEvent, GradeState> {
  final GradeRepository gradeRepository;

  GradeBloc({required this.gradeRepository}) : super(GradeInitial()) {
    on<FetchGradesEvent>(_onFetchGrades);
  }

  Future<void> _onFetchGrades(
    FetchGradesEvent event,
    Emitter<GradeState> emit,
  ) async {
    emit(GradeLoading());

    try {
      print('🎯 Fetching grades from repository...');

      final grades = await gradeRepository.getGrades();

      print('✅ Grades fetched successfully: ${grades.length} course group(s)');

      emit(GradeLoaded(courseGroups: grades));
    } on NetworkException catch (e) {
      print('❌ Network error: ${e.message}');
      emit(GradeError(message: e.message));
    } on ServerException catch (e) {
      print('❌ Server error: ${e.message}');
      emit(GradeError(message: e.message));
    } on UnauthorizedException catch (e) {
      print('❌ Unauthorized: ${e.message}');
      emit(GradeError(message: e.message));
    } on ValidationException catch (e) {
      print('❌ Validation error: ${e.message}');
      emit(GradeError(message: e.message));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(GradeError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(GradeError(message: 'An unexpected error occurred: $e'));
    }
  }
}
