// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/domain/repositories/grade_repository.dart';
import 'package:helium_mobile/presentation/bloc/gradeBloc/grade_event.dart';
import 'package:helium_mobile/presentation/bloc/gradeBloc/grade_state.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

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
      log.info('🎯 Fetching grades from repository...');

      final grades = await gradeRepository.getGrades();

      log.info(
        '✅ Grades fetched successfully: ${grades.length} course group(s)',
      );

      emit(GradeLoaded(courseGroups: grades));
    } on NetworkException catch (e) {
      log.info('❌ Network error: ${e.message}');
      emit(GradeError(message: e.message));
    } on ServerException catch (e) {
      log.info('❌ Server error: ${e.message}');
      emit(GradeError(message: e.message));
    } on UnauthorizedException catch (e) {
      log.info('❌ Unauthorized: ${e.message}');
      emit(GradeError(message: e.message));
    } on ValidationException catch (e) {
      log.info('❌ Validation error: ${e.message}');
      emit(GradeError(message: e.message));
    } on AppException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(GradeError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(GradeError(message: 'An unexpected error occurred: $e'));
    }
  }
}
