// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockCourseRepository mockCourseRepository;
  late MockCourseScheduleRepository mockCourseScheduleRepository;
  late MockCategoryRepository mockCategoryRepository;
  late CourseBloc courseBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockCourseRepository = MockCourseRepository();
    mockCourseScheduleRepository = MockCourseScheduleRepository();
    mockCategoryRepository = MockCategoryRepository();
    courseBloc = CourseBloc(
      courseRepository: mockCourseRepository,
      courseScheduleRepository: mockCourseScheduleRepository,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    courseBloc.close();
  });

  group('CourseBloc', () {
    test('initial state is CourseInitial with bloc origin', () {
      expect(courseBloc.state, isA<CourseInitial>());
    });

    group('FetchCoursesScreenDataEvent', () {
      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesScreenDataFetched] when data fetch succeeds',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return courseBloc;
        },
        act: (bloc) =>
            bloc.add(FetchCoursesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesScreenDataFetched>()
              .having((s) => s.courseGroups.length, 'courseGroups length', 2)
              .having((s) => s.courses.length, 'courses length', 3),
        ],
        verify: (_) {
          verify(() => mockCourseRepository.getCourseGroups()).called(1);
          verify(() => mockCourseRepository.getCourses()).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when getCourseGroups fails',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenThrow(ServerException(message: 'Server error'));
          return courseBloc;
        },
        act: (bloc) =>
            bloc.add(FetchCoursesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] with unexpected error message',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenThrow(Exception('Unknown error'));
          return courseBloc;
        },
        act: (bloc) =>
            bloc.add(FetchCoursesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('FetchCourseScreenDataEvent', () {
      const courseGroupId = 1;
      const courseId = 1;

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseScreenDataFetched] with course when courseId is provided',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroup(courseGroupId),
          ).thenAnswer((_) async => MockModels.createCourseGroup());
          when(
            () => mockCourseRepository.getCourse(courseGroupId, courseId),
          ).thenAnswer((_) async => MockModels.createCourse());
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseScreenDataEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseScreenDataFetched>()
              .having((s) => s.courseGroup.id, 'courseGroup id', courseGroupId)
              .having((s) => s.course?.id, 'course id', courseId),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseScreenDataFetched] with null course when courseId is null',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroup(courseGroupId),
          ).thenAnswer((_) async => MockModels.createCourseGroup());
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseScreenDataEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: null,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseScreenDataFetched>().having(
            (s) => s.course,
            'course',
            isNull,
          ),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when course group not found',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroup(courseGroupId),
          ).thenThrow(NotFoundException(message: 'Course group not found'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseScreenDataEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: null,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Course group not found',
          ),
        ],
      );
    });

    group('FetchCoursesEvent', () {
      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesFetched] when fetch succeeds without filter',
        build: () {
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: null),
          ).thenAnswer((_) async => MockModels.createCourses());
          return courseBloc;
        },
        act: (bloc) => bloc.add(FetchCoursesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesFetched>().having(
            (s) => s.courses.length,
            'courses length',
            3,
          ),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'passes shownOnCalendar filter to repository',
        build: () {
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourses(count: 1));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCoursesEvent(origin: EventOrigin.screen, shownOnCalendar: true),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesFetched>().having(
            (s) => s.courses.length,
            'courses length',
            1,
          ),
        ],
        verify: (_) {
          verify(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when fetch fails',
        build: () {
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: null),
          ).thenThrow(NetworkException(message: 'Connection failed'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(FetchCoursesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Connection failed',
          ),
        ],
      );
    });

    group('FetchCourseEvent', () {
      const courseGroupId = 1;
      const courseId = 2;

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseFetched] when fetch succeeds',
        build: () {
          when(
            () => mockCourseRepository.getCourse(courseGroupId, courseId),
          ).thenAnswer((_) async => MockModels.createCourse(id: courseId));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseFetched>().having(
            (s) => s.course.id,
            'course id',
            courseId,
          ),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when course not found',
        build: () {
          when(
            () => mockCourseRepository.getCourse(courseGroupId, courseId),
          ).thenThrow(NotFoundException(message: 'Course not found'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Course not found',
          ),
        ],
      );
    });

    group('DeleteCourseGroupEvent', () {
      const courseGroupId = 1;

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseGroupDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockCourseRepository.deleteCourseGroup(courseGroupId),
          ).thenAnswer((_) async {});
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCourseGroupEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseGroupDeleted>().having((s) => s.id, 'id', courseGroupId),
        ],
        verify: (_) {
          verify(
            () => mockCourseRepository.deleteCourseGroup(courseGroupId),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when deletion fails',
        build: () {
          when(
            () => mockCourseRepository.deleteCourseGroup(courseGroupId),
          ).thenThrow(ServerException(message: 'Cannot delete'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCourseGroupEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Cannot delete',
          ),
        ],
      );
    });

    group('DeleteCourseEvent', () {
      const courseGroupId = 1;
      const courseId = 2;

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockCourseRepository.deleteCourse(courseGroupId, courseId),
          ).thenAnswer((_) async {});
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCourseEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseDeleted>().having((s) => s.id, 'id', courseId),
        ],
        verify: (_) {
          verify(
            () => mockCourseRepository.deleteCourse(courseGroupId, courseId),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when course deletion fails',
        build: () {
          when(
            () => mockCourseRepository.deleteCourse(courseGroupId, courseId),
          ).thenThrow(NotFoundException(message: 'Course not found'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCourseEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Course not found',
          ),
        ],
      );
    });

    group('FetchCourseScheduleEvent', () {
      const courseGroupId = 1;
      const courseId = 2;

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseScheduleFetched] when fetch succeeds',
        build: () {
          when(
            () => mockCourseScheduleRepository.getCourseScheduleForCourse(
              courseGroupId,
              courseId,
            ),
          ).thenAnswer((_) async => MockModels.createCourseSchedule());
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseScheduleEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [isA<CoursesLoading>(), isA<CourseScheduleFetched>()],
        verify: (_) {
          verify(
            () => mockCourseScheduleRepository.getCourseScheduleForCourse(
              courseGroupId,
              courseId,
            ),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when schedule not found',
        build: () {
          when(
            () => mockCourseScheduleRepository.getCourseScheduleForCourse(
              courseGroupId,
              courseId,
            ),
          ).thenThrow(NotFoundException(message: 'Schedule not found'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseScheduleEvent(
            origin: EventOrigin.screen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Schedule not found',
          ),
        ],
      );
    });
  });
}
