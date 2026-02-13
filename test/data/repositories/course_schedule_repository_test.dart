// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/sources/course_schedule_builder_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';

class MockCourseScheduleRemoteDataSource extends Mock
    implements CourseScheduleRemoteDataSource {}

class MockCourseScheduleBuilderSource extends Mock
    implements CourseScheduleBuilderSource {}

void main() {
  late CourseScheduleRepositoryImpl repository;
  late MockCourseScheduleRemoteDataSource mockRemoteDataSource;
  late MockCourseScheduleBuilderSource mockBuilderSource;

  setUp(() {
    mockRemoteDataSource = MockCourseScheduleRemoteDataSource();
    mockBuilderSource = MockCourseScheduleBuilderSource();
    repository = CourseScheduleRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      builderSource: mockBuilderSource,
    );
  });

  setUpAll(() {
    registerFallbackValue(givenCourseScheduleRequestModel());
    registerFallbackValue(<CourseModel>[]);
  });

  group('CourseScheduleRepositoryImpl', () {
    group('getCourseScheduleEvents', () {
      test('delegates to builderSource and returns events', () async {
        // GIVEN
        final courses = [
          CourseModel.fromJson(givenCourseJson(id: 1, title: 'CS 101')),
        ];
        final from = DateTime(2025, 8, 1);
        final to = DateTime(2025, 12, 31);
        final expectedEvents = [
          CourseScheduleEventModel.fromJson(
            givenCourseScheduleEventJson(id: 1, title: 'CS 101'),
          ),
          CourseScheduleEventModel.fromJson(
            givenCourseScheduleEventJson(id: 2, title: 'CS 101'),
          ),
        ];

        when(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            search: any(named: 'search'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenReturn(expectedEvents);

        // WHEN
        final result = await repository.getCourseScheduleEvents(
          courses: courses,
          from: from,
          to: to,
        );

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('CS 101'));
        verify(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: courses,
            from: from,
            to: to,
            search: null,
            shownOnCalendar: null,
          ),
        ).called(1);
      });

      test('passes search parameter to builderSource', () async {
        // GIVEN
        final courses = <CourseModel>[];
        final from = DateTime(2025, 8, 1);
        final to = DateTime(2025, 12, 31);
        const search = 'CS 101';

        when(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            search: any(named: 'search'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenReturn([]);

        // WHEN
        await repository.getCourseScheduleEvents(
          courses: courses,
          from: from,
          to: to,
          search: search,
        );

        // THEN
        verify(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: courses,
            from: from,
            to: to,
            search: search,
            shownOnCalendar: null,
          ),
        ).called(1);
      });

      test('passes shownOnCalendar parameter to builderSource', () async {
        // GIVEN
        final courses = <CourseModel>[];
        final from = DateTime(2025, 8, 1);
        final to = DateTime(2025, 12, 31);

        when(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            search: any(named: 'search'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenReturn([]);

        // WHEN
        await repository.getCourseScheduleEvents(
          courses: courses,
          from: from,
          to: to,
          shownOnCalendar: true,
        );

        // THEN
        verify(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: courses,
            from: from,
            to: to,
            search: null,
            shownOnCalendar: true,
          ),
        ).called(1);
      });

      test('returns empty list when builderSource returns empty', () async {
        // GIVEN
        when(
          () => mockBuilderSource.buildCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            search: any(named: 'search'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenReturn([]);

        // WHEN
        final result = await repository.getCourseScheduleEvents(
          courses: [],
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
        );

        // THEN
        expect(result, isEmpty);
      });
    });

    group('getCourseSchedules', () {
      test('delegates to remoteDataSource', () async {
        // GIVEN
        final expectedSchedules = [
          CourseScheduleModel.fromJson(
            givenCourseScheduleJson(id: 1, daysOfWeek: '0101010'),
          ),
        ];

        when(
          () => mockRemoteDataSource.getCourseSchedules(
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => expectedSchedules);

        // WHEN
        final result = await repository.getCourseSchedules();

        // THEN
        expect(result.length, equals(1));
        expect(result[0].daysOfWeek, equals('0101010'));
      });
    });

    group('getCourseScheduleForCourse', () {
      test('delegates to remoteDataSource', () async {
        // GIVEN
        final expectedSchedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(id: 1, daysOfWeek: '1111100'),
        );

        when(
          () => mockRemoteDataSource.getCourseScheduleForCourse(any(), any()),
        ).thenAnswer((_) async => expectedSchedule);

        // WHEN
        final result = await repository.getCourseScheduleForCourse(1, 2);

        // THEN
        expect(result.daysOfWeek, equals('1111100'));
        verify(
          () => mockRemoteDataSource.getCourseScheduleForCourse(1, 2),
        ).called(1);
      });
    });

    group('createCourseSchedule', () {
      test('delegates to remoteDataSource', () async {
        // GIVEN
        final request = givenCourseScheduleRequestModel(daysOfWeek: '0101010');
        final expectedSchedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(id: 1, daysOfWeek: '0101010'),
        );

        when(
          () => mockRemoteDataSource.createCourseSchedule(any(), any(), any()),
        ).thenAnswer((_) async => expectedSchedule);

        // WHEN
        final result = await repository.createCourseSchedule(1, 2, request);

        // THEN
        expect(result.daysOfWeek, equals('0101010'));
        verify(
          () => mockRemoteDataSource.createCourseSchedule(1, 2, request),
        ).called(1);
      });
    });

    group('updateCourseSchedule', () {
      test('delegates to remoteDataSource', () async {
        // GIVEN
        final request = givenCourseScheduleRequestModel(daysOfWeek: '1111111');
        final expectedSchedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(id: 1, daysOfWeek: '1111111'),
        );

        when(
          () => mockRemoteDataSource.updateCourseSchedule(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => expectedSchedule);

        // WHEN
        final result = await repository.updateCourseSchedule(1, 2, 3, request);

        // THEN
        expect(result.daysOfWeek, equals('1111111'));
        verify(
          () => mockRemoteDataSource.updateCourseSchedule(1, 2, 3, request),
        ).called(1);
      });
    });
  });
}
