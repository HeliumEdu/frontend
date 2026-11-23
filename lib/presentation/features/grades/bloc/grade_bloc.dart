import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grades_model.dart';
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
    on<CalculateNeededGradeEvent>(_onCalculateNeededGrade);
    on<ResetGradesEvent>((event, emit) => emit(GradeInitial()));
  }

  Future<void> _onFetchGrades(
    FetchGradeScreenDataEvent event,
    Emitter<GradeState> emit,
  ) async {
    if (!event.background) emit(GradesLoading());

    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(forceRefresh: event.forceRefresh),
        gradeRepository.getGrades(forceRefresh: event.forceRefresh),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final grades = results[1] as GradesModel;

      emit(
        GradeScreenDataFetched(
          courseGroups: courseGroups,
          grades: grades.courseGroups,
          cumulativeGpa: grades.cumulativeGpa,
        ),
      );
    } on HeliumException catch (e) {
      emit(GradesError(message: e.message, background: event.background));
    } catch (e) {
      emit(GradesError(
        message: HeliumException.unexpectedError,
        background: event.background,
      ));
    }
  }

  Future<void> _onCalculateNeededGrade(
    CalculateNeededGradeEvent event,
    Emitter<GradeState> emit,
  ) async {
    emit(NeededGradeCalculating());

    try {
      final result = await gradeRepository.getNeededGrade(
        courseId: event.courseId,
        targetId: event.targetId,
        desiredGrade: event.desiredGrade,
        desiredGpa: event.desiredGpa,
      );
      emit(NeededGradeCalculated(
        courseId: event.courseId,
        targetId: event.targetId,
        desiredGrade: event.desiredGrade,
        desiredGpa: event.desiredGpa,
        result: result,
      ));
    } on HeliumException catch (e) {
      emit(NeededGradeError(
        courseId: event.courseId,
        targetId: event.targetId,
        desiredGrade: event.desiredGrade,
        desiredGpa: event.desiredGpa,
        message: e.message,
      ));
    } catch (e) {
      emit(NeededGradeError(
        courseId: event.courseId,
        targetId: event.targetId,
        desiredGrade: event.desiredGrade,
        desiredGpa: event.desiredGpa,
        message: HeliumException.unexpectedError,
      ));
    }
  }
}
