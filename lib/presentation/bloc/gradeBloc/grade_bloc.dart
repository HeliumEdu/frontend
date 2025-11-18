import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:helium_student_flutter/domain/repositories/grade_repository.dart';
import 'package:helium_student_flutter/presentation/bloc/gradeBloc/grade_event.dart';
import 'package:helium_student_flutter/presentation/bloc/gradeBloc/grade_state.dart';

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
