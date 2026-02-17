// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockCourseRepository mockCourseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late PlannerBloc calendarBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockCourseRepository = MockCourseRepository();
    mockCategoryRepository = MockCategoryRepository();
    calendarBloc = PlannerBloc(
      courseRepository: mockCourseRepository,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    calendarBloc.close();
  });

  group('CalendarBloc', () {
    test('initial state is CalendarInitial', () {
      expect(calendarBloc.state, isA<PlannerInitial>());
    });

    group('FetchCalendarScreenDataEvent', () {
      blocTest<PlannerBloc, PlannerState>(
        'emits [CalendarLoading, CalendarScreenDataFetched] when data fetch succeeds',
        build: () {
          when(
                () => mockCourseRepository.getCourseGroups(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourses(count: 2));
          when(() => mockCategoryRepository.getCategories(shownOnCalendar: true)).thenAnswer(
            (_) async => [
              MockModels.createCategory(id: 1, title: 'Homework'),
              MockModels.createCategory(id: 2, title: 'Exam'),
            ],
          );
          return calendarBloc;
        },
        act: (bloc) => bloc.add(FetchPlannerScreenDataEvent()),
        expect: () => [
          isA<PlannerLoading>(),
          isA<PlannerScreenDataFetched>()
              .having((s) => s.courses.length, 'courses length', 2)
              .having((s) => s.categories.length, 'categories length', 2),
        ],
        verify: (_) {
          verify(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).called(1);
          verify(() => mockCategoryRepository.getCategories(shownOnCalendar: true)).called(1);
        },
      );

      blocTest<PlannerBloc, PlannerState>(
        'emits [CalendarLoading, CalendarError] when getCourses fails',
        build: () {
          when(
                () => mockCourseRepository.getCourseGroups(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenThrow(NetworkException(message: 'Network error'));
          return calendarBloc;
        },
        act: (bloc) => bloc.add(FetchPlannerScreenDataEvent()),
        expect: () => [
          isA<PlannerLoading>(),
          isA<PlannerError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ],
      );

      blocTest<PlannerBloc, PlannerState>(
        'emits [CalendarLoading, CalendarError] when getCategories fails',
        build: () {
          when(
                () => mockCourseRepository.getCourseGroups(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourses());
          when(
            () => mockCategoryRepository.getCategories(shownOnCalendar: true),
          ).thenThrow(ServerException(message: 'Server unavailable'));
          return calendarBloc;
        },
        act: (bloc) => bloc.add(FetchPlannerScreenDataEvent()),
        expect: () => [
          isA<PlannerLoading>(),
          isA<PlannerError>().having(
            (e) => e.message,
            'message',
            'Server unavailable',
          ),
        ],
      );

      blocTest<PlannerBloc, PlannerState>(
        'emits [CalendarLoading, CalendarError] with generic message for unexpected errors',
        build: () {
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenThrow(Exception('Something went wrong'));
          return calendarBloc;
        },
        act: (bloc) => bloc.add(FetchPlannerScreenDataEvent()),
        expect: () => [
          isA<PlannerLoading>(),
          isA<PlannerError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );

      blocTest<PlannerBloc, PlannerState>(
        'handles empty courses and categories',
        build: () {
          when(
                () => mockCourseRepository.getCourseGroups(shownOnCalendar: true),
          ).thenAnswer((_) async => []);
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenAnswer((_) async => []);
          when(
            () => mockCategoryRepository.getCategories(shownOnCalendar: true),
          ).thenAnswer((_) async => []);
          return calendarBloc;
        },
        act: (bloc) => bloc.add(FetchPlannerScreenDataEvent()),
        expect: () => [
          isA<PlannerLoading>(),
          isA<PlannerScreenDataFetched>()
              .having((s) => s.courseGroups, 'courseGroups', isEmpty)
              .having((s) => s.courses, 'courses', isEmpty)
              .having((s) => s.categories, 'categories', isEmpty),
        ],
      );
    });
  });
}
