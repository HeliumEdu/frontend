import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_event.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockGradeRepository mockGradeRepository;
  late MockCourseRepository mockCourseRepository;
  late GradeBloc gradeBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockGradeRepository = MockGradeRepository();
    mockCourseRepository = MockCourseRepository();
    gradeBloc = GradeBloc(
      gradeRepository: mockGradeRepository,
      courseRepository: mockCourseRepository,
    );
  });

  tearDown(() {
    gradeBloc.close();
  });

  group('GradeBloc', () {
    test('initial state is GradeInitial', () {
      expect(gradeBloc.state, isA<GradeInitial>());
    });

    group('FetchGradeScreenDataEvent', () {
      blocTest<GradeBloc, GradeState>(
        'emits [GradesLoading, GradeScreenDataFetched] when data fetch succeeds',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockGradeRepository.getGrades(),
          ).thenAnswer((_) async => MockModels.createGradeCourseGroups());
          return gradeBloc;
        },
        act: (bloc) => bloc.add(FetchGradeScreenDataEvent()),
        expect: () => [
          isA<GradesLoading>(),
          isA<GradeScreenDataFetched>()
              .having((s) => s.courseGroups.length, 'courseGroups length', 2)
              .having((s) => s.grades.length, 'grades length', 2),
        ],
        verify: (_) {
          verify(() => mockCourseRepository.getCourseGroups()).called(1);
          verify(() => mockGradeRepository.getGrades()).called(1);
        },
      );

      blocTest<GradeBloc, GradeState>(
        'emits [GradesLoading, GradesError] when getCourseGroups fails',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenThrow(ServerException(message: 'Server error'));
          return gradeBloc;
        },
        act: (bloc) => bloc.add(FetchGradeScreenDataEvent()),
        expect: () => [
          isA<GradesLoading>(),
          isA<GradesError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<GradeBloc, GradeState>(
        'emits [GradesLoading, GradesError] when getGrades fails',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockGradeRepository.getGrades(),
          ).thenThrow(NetworkException(message: 'Connection timeout'));
          return gradeBloc;
        },
        act: (bloc) => bloc.add(FetchGradeScreenDataEvent()),
        expect: () => [
          isA<GradesLoading>(),
          isA<GradesError>().having(
            (e) => e.message,
            'message',
            'Connection timeout',
          ),
        ],
      );

      blocTest<GradeBloc, GradeState>(
        'emits [GradesLoading, GradesError] with generic message for unexpected errors',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenThrow(Exception('Unknown error'));
          return gradeBloc;
        },
        act: (bloc) => bloc.add(FetchGradeScreenDataEvent()),
        expect: () => [
          isA<GradesLoading>(),
          isA<GradesError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );

      blocTest<GradeBloc, GradeState>(
        'handles empty grades data',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenAnswer((_) async => []);
          when(
            () => mockGradeRepository.getGrades(),
          ).thenAnswer((_) async => []);
          return gradeBloc;
        },
        act: (bloc) => bloc.add(FetchGradeScreenDataEvent()),
        expect: () => [
          isA<GradesLoading>(),
          isA<GradeScreenDataFetched>()
              .having((s) => s.courseGroups, 'courseGroups', isEmpty)
              .having((s) => s.grades, 'grades', isEmpty),
        ],
      );
    });

    group('CalculateNeededGradeEvent', () {
      blocTest<GradeBloc, GradeState>(
        'emits [NeededGradeCalculating, NeededGradeCalculated] with the inputs it answers',
        build: () {
          when(
            () => mockGradeRepository.getNeededGrade(
              courseId: 1,
              targetId: 2,
              desiredGrade: 85,
            ),
          ).thenAnswer(
            (_) async => NeededGradeModel(
              state: NeededGradeState.achievable,
              neededGrade: 77.5,
              weighted: true,
            ),
          );
          return gradeBloc;
        },
        act: (bloc) => bloc.add(
          CalculateNeededGradeEvent(courseId: 1, targetId: 2, desiredGrade: 85),
        ),
        expect: () => [
          isA<NeededGradeCalculating>(),
          isA<NeededGradeCalculated>()
              .having(
                (s) => (s.courseId, s.targetId, s.desiredGrade),
                'inputs',
                (1, 2, 85.0),
              )
              .having((s) => s.result.neededGrade, 'neededGrade', 77.5),
        ],
      );

      blocTest<GradeBloc, GradeState>(
        'emits [NeededGradeCalculating, NeededGradeError] when the calculation fails',
        build: () {
          when(
            () => mockGradeRepository.getNeededGrade(
              courseId: 1,
              targetId: 2,
              desiredGrade: 85,
            ),
          ).thenThrow(
            ValidationException(
              message: 'Select an ungraded assignment in this class.',
            ),
          );
          return gradeBloc;
        },
        act: (bloc) => bloc.add(
          CalculateNeededGradeEvent(courseId: 1, targetId: 2, desiredGrade: 85),
        ),
        expect: () => [
          isA<NeededGradeCalculating>(),
          isA<NeededGradeError>().having(
            (e) => e.message,
            'message',
            'Select an ungraded assignment in this class.',
          ),
        ],
      );
    });
  });
}
