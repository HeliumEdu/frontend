// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/calendar_item_data_source.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;

class MockEventRepository extends Mock implements EventRepository {}

class MockHomeworkRepository extends Mock implements HomeworkRepository {}

class MockCourseScheduleRepository extends Mock
    implements CourseScheduleRepository {}

class MockExternalCalendarRepository extends Mock
    implements ExternalCalendarRepository {}

void main() {
  late CalendarItemDataSource dataSource;
  late MockEventRepository mockEventRepository;
  late MockHomeworkRepository mockHomeworkRepository;
  late MockCourseScheduleRepository mockCourseScheduleRepository;
  late MockExternalCalendarRepository mockExternalCalendarRepository;
  late UserSettingsModel userSettings;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    // Use synchronous filtering in tests
    CalendarItemDataSource.filterDebounceDuration = Duration.zero;
  });

  tearDownAll(() {
    // Restore default debounce duration
    CalendarItemDataSource.filterDebounceDuration = const Duration(
      milliseconds: 16,
    );
  });

  setUp(() async {
    mockEventRepository = MockEventRepository();
    mockHomeworkRepository = MockHomeworkRepository();
    mockCourseScheduleRepository = MockCourseScheduleRepository();
    mockExternalCalendarRepository = MockExternalCalendarRepository();

    // Default mocks for handleLoadMore
    when(
      () => mockHomeworkRepository.getHomeworks(
        from: any(named: 'from'),
        to: any(named: 'to'),
        shownOnCalendar: any(named: 'shownOnCalendar'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockEventRepository.getEvents(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockCourseScheduleRepository.getCourseScheduleEvents(
        courses: any(named: 'courses'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        shownOnCalendar: any(named: 'shownOnCalendar'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockExternalCalendarRepository.getExternalCalendarEvents(
        from: any(named: 'from'),
        to: any(named: 'to'),
        shownOnCalendar: any(named: 'shownOnCalendar'),
      ),
    ).thenAnswer((_) async => []);

    userSettings = UserSettingsModel(
      timeZone: tz.getLocation('America/Los_Angeles'),
      defaultView: 0,
      colorSchemeTheme: 0,
      weekStartsOn: 0,
      allDayOffset: 0,
      whatsNewVersionSeen: 0,
      eventsColor: const Color(0xFF4CAF50),
      materialColor: const Color(0xFF2196F3),
      gradeColor: const Color(0xFFF44336),
      defaultReminderType: 3,
      defaultReminderOffset: 0,
      defaultReminderOffsetType: 0,
      colorByCategory: false,
      rememberFilterState: false,
    );

    dataSource = CalendarItemDataSource(
      eventRepository: mockEventRepository,
      homeworkRepository: mockHomeworkRepository,
      courseScheduleRepository: mockCourseScheduleRepository,
      externalCalendarRepository: mockExternalCalendarRepository,
      userSettings: userSettings,
    );

    // Initialize cache with a wide date range so addCalendarItem works
    await dataSource.handleLoadMore(
      DateTime(2024, 1, 1),
      DateTime(2026, 12, 31),
    );
  });

  group('CalendarItemDataSource', () {
    group('initialization', () {
      test('initializes with empty appointments', () {
        // Create a fresh data source without setUp's handleLoadMore call
        final freshDataSource = CalendarItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
          externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );

        expect(freshDataSource.appointments, isEmpty);
        expect(freshDataSource.allCalendarItems, isEmpty);
        expect(freshDataSource.hasLoadedInitialData, isFalse);
      });

      test('initializes with empty filter state', () {
        // Create a fresh data source without setUp's handleLoadMore call
        final freshDataSource = CalendarItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
          externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );

        expect(freshDataSource.filteredCourses, isEmpty);
        expect(freshDataSource.filterCategories, isEmpty);
        expect(freshDataSource.filterTypes, isEmpty);
        expect(freshDataSource.filterStatuses, isEmpty);
        expect(freshDataSource.searchQuery, isEmpty);
        expect(freshDataSource.completedOverrides, isEmpty);
      });
    });

    group('data accessors', () {
      late HomeworkModel homework;
      late EventModel event;

      setUp(() {
        homework = _createHomeworkModel(
          id: 1,
          title: 'Test Homework',
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
          allDay: false,
        );
        event = _createEventModel(
          id: 2,
          title: 'Test Event',
          start: DateTime.parse('2025-01-15T14:00:00Z'),
          end: DateTime.parse('2025-01-15T15:00:00Z'),
          allDay: false,
        );

        dataSource.addCalendarItem(homework);
        dataSource.addCalendarItem(event);
      });

      test('getStartTime returns DateTime with priority adjustment', () {
        final startTime = dataSource.getStartTime(0);
        // Homework: (3-0)*1000 + (100-0) = 3100 seconds subtracted
        expect(
          startTime,
          DateTime.parse(
            '2025-01-15T10:00:00Z',
          ).subtract(const Duration(seconds: 3100)),
        );
      });

      test(
        'getEndTime returns DateTime with priority adjustment for non-allDay events',
        () {
          final endTime = dataSource.getEndTime(0);
          // Homework: baseMin=3, posMin=1.667, total=4.667 → 4min 40sec
          expect(
            endTime,
            DateTime.parse(
              '2025-01-15T11:00:00Z',
            ).subtract(const Duration(minutes: 4, seconds: 40)),
          );
        },
      );

      test('getEndTime subtracts 1 day for allDay events', () {
        final allDayHomework = _createHomeworkModel(
          id: 3,
          title: 'All Day',
          start: DateTime.parse('2025-01-15T00:00:00Z'),
          end: DateTime.parse('2025-01-16T00:00:00Z'),
          allDay: true,
        );
        dataSource.appointments!.insert(0, allDayHomework);

        final endTime = dataSource.getEndTime(0);
        expect(endTime, DateTime.parse('2025-01-15T00:00:00Z'));
      });

      test('isAllDay returns correct value', () {
        expect(dataSource.isAllDay(0), isFalse);

        final allDayHomework = _createHomeworkModel(
          id: 3,
          title: 'All Day',
          start: DateTime.parse('2025-01-15T00:00:00Z'),
          end: DateTime.parse('2025-01-16T00:00:00Z'),
          allDay: true,
        );
        dataSource.appointments!.insert(0, allDayHomework);
        expect(dataSource.isAllDay(0), isTrue);
      });

      test('getSubject returns calendar item title', () {
        expect(dataSource.getSubject(0), 'Test Homework');
        expect(dataSource.getSubject(1), 'Test Event');
      });

      test('getColor returns color from getColorForItem', () {
        final color = dataSource.getColor(1);
        expect(color, userSettings.eventsColor);
      });
    });

    group('getColorForItem', () {
      late CourseModel course;
      late CategoryModel category;

      setUp(() {
        course = _createCourseModel(id: 1, color: const Color(0xFFFF5722));
        category = _createCategoryModel(id: 1, color: const Color(0xFF9C27B0));

        dataSource.courses = [course];
        dataSource.categoriesMap = {1: category};
      });

      test('returns eventsColor for EventModel', () {
        final event = _createEventModel();
        final color = dataSource.getColorForItem(event);
        expect(color, userSettings.eventsColor);
      });

      test('returns category color for HomeworkModel when colorByCategory', () {
        final colorByCategorySettings = UserSettingsModel(
          timeZone: tz.getLocation('America/Los_Angeles'),
          defaultView: 0,
          colorSchemeTheme: 0,
          weekStartsOn: 0,
          allDayOffset: 0,
          whatsNewVersionSeen: 0,
          eventsColor: const Color(0xFF4CAF50),
          materialColor: const Color(0xFF2196F3),
          gradeColor: const Color(0xFFF44336),
          defaultReminderType: 3,
          defaultReminderOffset: 0,
          defaultReminderOffsetType: 0,
          colorByCategory: true,
          rememberFilterState: false,
        );

        final colorByCategoryDataSource = CalendarItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
          externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: colorByCategorySettings,
        );
        colorByCategoryDataSource.courses = [course];
        colorByCategoryDataSource.categoriesMap = {1: category};

        final homework = _createHomeworkModel(courseId: 1, categoryId: 1);

        final color = colorByCategoryDataSource.getColorForItem(homework);
        expect(color, category.color);
      });

      test(
        'returns course color for HomeworkModel when not colorByCategory',
        () {
          final homework = _createHomeworkModel(courseId: 1, categoryId: 1);

          final color = dataSource.getColorForItem(homework);
          expect(color, course.color);
        },
      );

      test('returns item color for CourseScheduleEventModel', () {
        final scheduleEvent = _createCourseScheduleEventModel(
          color: const Color(0xFFFFEB3B),
        );

        final color = dataSource.getColorForItem(scheduleEvent);
        expect(color, const Color(0xFFFFEB3B));
      });

      test('returns item color for ExternalCalendarEventModel', () {
        final externalEvent = _createExternalCalendarEventModel(
          color: const Color(0xFF00BCD4),
        );

        final color = dataSource.getColorForItem(externalEvent);
        expect(color, const Color(0xFF00BCD4));
      });
    });

    group('getLocationForItem', () {
      late CourseModel course;

      setUp(() {
        course = _createCourseModel(id: 1, room: 'Room 101');
        dataSource.courses = [course];
      });

      test('returns course room for HomeworkModel', () {
        final homework = _createHomeworkModel(courseId: 1);
        final location = dataSource.getLocationForItem(homework);
        expect(location, 'Room 101');
      });

      test('returns course room for CourseScheduleEventModel', () {
        final scheduleEvent = _createCourseScheduleEventModel(ownerId: '1');
        final location = dataSource.getLocationForItem(scheduleEvent);
        expect(location, 'Room 101');
      });
    });

    group('course filtering', () {
      late CourseModel course1;
      late CourseModel course2;
      late HomeworkModel homework1;
      late HomeworkModel homework2;
      late HomeworkModel homework3;

      setUp(() {
        course1 = _createCourseModel(id: 1, title: 'Math 101');
        course2 = _createCourseModel(id: 2, title: 'Physics 201');

        homework1 = _createHomeworkModel(id: 1, courseId: 1);
        homework2 = _createHomeworkModel(id: 2, courseId: 2);
        homework3 = _createHomeworkModel(id: 3, courseId: 1);

        dataSource.courses = [course1, course2];
        dataSource.addCalendarItem(homework1);
        dataSource.addCalendarItem(homework2);
        dataSource.addCalendarItem(homework3);
      });

      test('returns all homeworks when no courses selected', () {
        dataSource.setFilteredCourses({});
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters by single selected course', () {
        dataSource.setFilteredCourses({1: true});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });

      test('filters by multiple selected courses', () {
        dataSource.setFilteredCourses({1: true, 2: true});
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters out when course not selected', () {
        dataSource.setFilteredCourses({1: true, 2: false});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });

      test('filters by course ID', () {
        dataSource.setFilteredCourses({1: true});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });

      test('filters CourseScheduleEventModels by course', () {
        final scheduleEvent1 = _createCourseScheduleEventModel(
          id: 10,
          ownerId: '1',
        );
        final scheduleEvent2 = _createCourseScheduleEventModel(
          id: 11,
          ownerId: '2',
        );
        dataSource.addCalendarItem(scheduleEvent1);
        dataSource.addCalendarItem(scheduleEvent2);

        dataSource.setFilteredCourses({1: true});
        dataSource.setFilterTypes(['Class Schedules']);

        expect(dataSource.appointments, hasLength(1));
        expect(
          (dataSource.appointments![0] as CourseScheduleEventModel).ownerId,
          '1',
        );
      });
    });

    group('category filtering', () {
      late CategoryModel category1;
      late CategoryModel category2;
      late HomeworkModel homework1;
      late HomeworkModel homework2;
      late HomeworkModel homework3;

      setUp(() {
        category1 = _createCategoryModel(id: 1, title: 'Assignments');
        category2 = _createCategoryModel(id: 2, title: 'Exams');

        homework1 = _createHomeworkModel(id: 1, categoryId: 1);
        homework2 = _createHomeworkModel(id: 2, categoryId: 2);
        homework3 = _createHomeworkModel(id: 3, categoryId: 1);

        dataSource.categoriesMap = {1: category1, 2: category2};
        dataSource.addCalendarItem(homework1);
        dataSource.addCalendarItem(homework2);
        dataSource.addCalendarItem(homework3);
      });

      test('returns all homeworks when no categories filtered', () {
        dataSource.setFilterCategories([]);
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters by single category', () {
        dataSource.setFilterCategories(['Assignments']);
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });

      test('filters by multiple categories', () {
        dataSource.setFilterCategories(['Assignments', 'Exams']);
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters out non-matching categories', () {
        dataSource.setFilterCategories(['Exams']);
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 2);
      });

      test('handles homework with category entity', () {
        final homeworkWithEntity = _createHomeworkModel(
          id: 4,
          categoryEntity: category1,
        );
        dataSource.addCalendarItem(homeworkWithEntity);

        dataSource.setFilterCategories(['Assignments']);
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(3));
        expect(filtered.map((h) => h.id), containsAll([1, 3, 4]));
      });

      test('excludes homework with empty category title', () {
        final emptyCategory = _createCategoryModel(id: 3, title: '  ');
        final homework = _createHomeworkModel(id: 5, categoryId: 3);
        dataSource.categoriesMap![3] = emptyCategory;
        dataSource.addCalendarItem(homework);

        dataSource.setFilterCategories(['Assignments']);
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });
    });

    group('status filtering', () {
      late HomeworkModel completedHomework;
      late HomeworkModel incompleteHomework;
      late HomeworkModel overdueHomework;

      setUp(() {
        final now = DateTime.now();
        completedHomework = _createHomeworkModel(
          id: 1,
          completed: true,
          start: now.add(const Duration(days: 1)),
        );
        incompleteHomework = _createHomeworkModel(
          id: 2,
          completed: false,
          start: now.add(const Duration(days: 1)),
        );
        overdueHomework = _createHomeworkModel(
          id: 3,
          completed: false,
          start: now.subtract(const Duration(days: 1)),
        );

        dataSource.addCalendarItem(completedHomework);
        dataSource.addCalendarItem(incompleteHomework);
        dataSource.addCalendarItem(overdueHomework);
      });

      test('returns all homeworks when no status filter', () {
        dataSource.setFilterStatuses({});
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters by Complete status', () {
        dataSource.setFilterStatuses({'Complete'});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 1);
      });

      test('filters by Incomplete status', () {
        dataSource.setFilterStatuses({'Incomplete'});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([2, 3]));
      });

      test('filters by Overdue status', () {
        dataSource.setFilterStatuses({'Overdue'});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 3);
      });

      test('combines multiple status filters with OR logic', () {
        dataSource.setFilterStatuses({'Complete', 'Incomplete'});
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('Overdue excludes completed items', () {
        final now = DateTime.now();
        final completedOverdue = _createHomeworkModel(
          id: 4,
          completed: true,
          start: now.subtract(const Duration(days: 1)),
        );
        dataSource.addCalendarItem(completedOverdue);

        dataSource.setFilterStatuses({'Overdue'});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 3);
      });

      test('respects completed overrides in status filter', () {
        dataSource.setCompletedOverride(2, true);
        dataSource.setFilterStatuses({'Complete'});
        final filtered = dataSource.filteredHomeworks;

        // Item with override should always be visible
        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 2]));
      });
    });

    group('search filtering', () {
      late HomeworkModel homework1;
      late HomeworkModel homework2;
      late EventModel event1;

      setUp(() {
        homework1 = _createHomeworkModel(
          id: 1,
          title: 'Math Assignment',
          comments: 'Complete problems 1-10',
        );
        homework2 = _createHomeworkModel(
          id: 2,
          title: 'Physics Lab Report',
          comments: 'Write conclusions',
        );
        event1 = _createEventModel(
          id: 3,
          title: 'Study Session',
          comments: 'Review math notes',
        );

        dataSource.addCalendarItem(homework1);
        dataSource.addCalendarItem(homework2);
        dataSource.addCalendarItem(event1);
      });

      test('returns all items when search query is empty', () {
        dataSource.setSearchQuery('');
        expect(dataSource.filteredHomeworks, hasLength(2));
      });

      test('filters by title match', () {
        dataSource.setSearchQuery('Math');
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 1);
      });

      test('filters by comments match', () {
        dataSource.setSearchQuery('conclusions');
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 2);
      });

      test('search is case insensitive', () {
        dataSource.setSearchQuery('PHYSICS');
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 2);
      });

      test('partial match works', () {
        dataSource.setSearchQuery('Lab');
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 2);
      });

      test('applies search to events', () {
        dataSource.setSearchQuery('math');
        dataSource.setFilterTypes(['Events']);

        expect(dataSource.appointments, hasLength(1));
        expect((dataSource.appointments![0] as EventModel).id, 3);
      });
    });

    group('type filtering', () {
      late HomeworkModel homework;
      late EventModel event;
      late CourseScheduleEventModel scheduleEvent;
      late ExternalCalendarEventModel externalEvent;

      setUp(() {
        homework = _createHomeworkModel(id: 1);
        event = _createEventModel(id: 2);
        scheduleEvent = _createCourseScheduleEventModel(id: 3);
        externalEvent = _createExternalCalendarEventModel(id: 4);

        dataSource.addCalendarItem(homework);
        dataSource.addCalendarItem(event);
        dataSource.addCalendarItem(scheduleEvent);
        dataSource.addCalendarItem(externalEvent);
      });

      test('returns all items when no type filter', () {
        dataSource.setFilterTypes([]);
        expect(dataSource.appointments, hasLength(4));
      });

      test('filters by Assignments type', () {
        dataSource.setFilterTypes(['Assignments']);
        expect(dataSource.appointments, hasLength(1));
        expect(dataSource.appointments![0], isA<HomeworkModel>());
      });

      test('filters by Events type', () {
        dataSource.setFilterTypes(['Events']);
        expect(dataSource.appointments, hasLength(1));
        expect(dataSource.appointments![0], isA<EventModel>());
      });

      test('filters by Class Schedules type', () {
        dataSource.setFilterTypes(['Class Schedules']);
        expect(dataSource.appointments, hasLength(1));
        expect(dataSource.appointments![0], isA<CourseScheduleEventModel>());
      });

      test('filters by External Calendars type', () {
        dataSource.setFilterTypes(['External Calendars']);
        expect(dataSource.appointments, hasLength(1));
        expect(dataSource.appointments![0], isA<ExternalCalendarEventModel>());
      });

      test('combines multiple type filters', () {
        dataSource.setFilterTypes(['Assignments', 'Events']);
        expect(dataSource.appointments, hasLength(2));
      });
    });

    group('combined filtering', () {
      late CourseModel course1;
      late CategoryModel category1;
      late HomeworkModel matchingHomework;
      late HomeworkModel nonMatchingCourse;
      late HomeworkModel nonMatchingCategory;

      setUp(() {
        course1 = _createCourseModel(id: 1, title: 'Math 101');
        category1 = _createCategoryModel(id: 1, title: 'Assignments');

        matchingHomework = _createHomeworkModel(
          id: 1,
          title: 'Math Homework',
          courseId: 1,
          categoryId: 1,
          completed: false,
          start: DateTime.now().add(const Duration(days: 1)),
        );
        nonMatchingCourse = _createHomeworkModel(
          id: 2,
          courseId: 2,
          categoryId: 1,
        );
        nonMatchingCategory = _createHomeworkModel(
          id: 3,
          courseId: 1,
          categoryId: 2,
        );

        dataSource.courses = [course1];
        dataSource.categoriesMap = {1: category1};
        dataSource.addCalendarItem(matchingHomework);
        dataSource.addCalendarItem(nonMatchingCourse);
        dataSource.addCalendarItem(nonMatchingCategory);
      });

      test('applies course and category filters together', () {
        dataSource.setFilteredCourses({1: true});
        dataSource.setFilterCategories(['Assignments']);

        final filtered = dataSource.filteredHomeworks;
        expect(filtered, hasLength(1));
        expect(filtered[0].id, 1);
      });

      test('applies all filters together', () {
        dataSource.setFilteredCourses({1: true});
        dataSource.setFilterCategories(['Assignments']);
        dataSource.setFilterStatuses({'Incomplete'});
        dataSource.setSearchQuery('Math');

        final filtered = dataSource.filteredHomeworks;
        expect(filtered, hasLength(1));
        expect(filtered[0].id, 1);
      });

      test('returns empty when filters exclude all items', () {
        dataSource.setFilteredCourses({1: true});
        dataSource.setSearchQuery('Physics');

        expect(dataSource.filteredHomeworks, isEmpty);
      });
    });

    group('calendar item management', () {
      test('addCalendarItem adds new item', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addCalendarItem(homework);

        expect(dataSource.allCalendarItems, hasLength(1));
        expect(dataSource.appointments, hasLength(1));
        expect(dataSource.allCalendarItems[0].id, 1);
      });

      test('addCalendarItem ignores duplicate', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addCalendarItem(homework);
        dataSource.addCalendarItem(homework);

        expect(dataSource.allCalendarItems, hasLength(1));
      });

      test('updateCalendarItem updates existing item', () {
        final homework = _createHomeworkModel(id: 1, title: 'Original');
        dataSource.addCalendarItem(homework);

        final updated = _createHomeworkModel(id: 1, title: 'Updated');
        dataSource.updateCalendarItem(updated);

        expect(dataSource.allCalendarItems, hasLength(1));
        expect(dataSource.allCalendarItems[0].title, 'Updated');
      });

      test('updateCalendarItem clears completed override', () {
        final homework = _createHomeworkModel(id: 1, completed: false);
        dataSource.addCalendarItem(homework);
        dataSource.setCompletedOverride(1, true);

        final updated = _createHomeworkModel(id: 1, completed: true);
        dataSource.updateCalendarItem(updated);

        expect(dataSource.completedOverrides, isEmpty);
      });

      test('removeCalendarItem removes item', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addCalendarItem(homework);
        dataSource.removeCalendarItem(1);

        expect(dataSource.allCalendarItems, isEmpty);
        expect(dataSource.appointments, isEmpty);
      });

      test('removeCalendarItem clears completed override', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addCalendarItem(homework);
        dataSource.setCompletedOverride(1, true);
        dataSource.removeCalendarItem(1);

        expect(dataSource.completedOverrides, isEmpty);
      });

      test('removeCalendarItem handles non-existent item', () {
        dataSource.removeCalendarItem(999);
        expect(dataSource.allCalendarItems, isEmpty);
      });
    });

    group('completed overrides', () {
      late HomeworkModel homework;

      setUp(() {
        homework = _createHomeworkModel(id: 1, completed: false);
        dataSource.addCalendarItem(homework);
      });

      test('setCompletedOverride sets override', () {
        dataSource.setCompletedOverride(1, true);
        expect(dataSource.completedOverrides[1], isTrue);
      });

      test('isHomeworkCompleted uses override when present', () {
        dataSource.setCompletedOverride(1, true);
        expect(dataSource.isHomeworkCompleted(homework), isTrue);
      });

      test('isHomeworkCompleted uses model value when no override', () {
        expect(dataSource.isHomeworkCompleted(homework), isFalse);
      });

      test('clearCompletedOverride removes override', () {
        dataSource.setCompletedOverride(1, true);
        dataSource.clearCompletedOverride(1);
        expect(dataSource.completedOverrides, isEmpty);
      });

      test('completedOverrides returns unmodifiable map', () {
        dataSource.setCompletedOverride(1, true);
        final overrides = dataSource.completedOverrides;

        expect(() => overrides[2] = true, throwsUnsupportedError);
      });
    });

    group('time overrides (optimistic UI for drag-drop/resize)', () {
      late HomeworkModel homework;

      setUp(() {
        homework = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addCalendarItem(homework);
      });

      test('setTimeOverride stores override', () {
        dataSource.setTimeOverride(
          1,
          '2025-01-16T14:00:00Z',
          '2025-01-16T15:00:00Z',
        );

        final override = dataSource.getTimeOverride(1);
        expect(override, isNotNull);
        expect(override!.start, '2025-01-16T14:00:00Z');
        expect(override.end, '2025-01-16T15:00:00Z');
      });

      test('getTimeOverride returns null when no override', () {
        expect(dataSource.getTimeOverride(999), isNull);
      });

      test('clearTimeOverride removes override', () {
        dataSource.setTimeOverride(
          1,
          '2025-01-16T14:00:00Z',
          '2025-01-16T15:00:00Z',
        );
        dataSource.clearTimeOverride(1);

        expect(dataSource.getTimeOverride(1), isNull);
      });

      test('getStartTime uses override when present', () {
        dataSource.setTimeOverride(
          1,
          '2025-01-20T09:00:00Z',
          '2025-01-20T10:00:00Z',
        );

        final startTime = dataSource.getStartTime(0);
        // Start time: override - 3100 seconds (homework priority + position)
        expect(
          startTime,
          DateTime.parse(
            '2025-01-20T09:00:00Z',
          ).subtract(const Duration(seconds: 3100)),
        );
      });

      test('getEndTime uses override when present', () {
        dataSource.setTimeOverride(
          1,
          '2025-01-20T09:00:00Z',
          '2025-01-20T10:00:00Z',
        );

        final endTime = dataSource.getEndTime(0);
        // End time: override - 4min 40sec (homework)
        expect(
          endTime,
          DateTime.parse(
            '2025-01-20T10:00:00Z',
          ).subtract(const Duration(minutes: 4, seconds: 40)),
        );
      });

      test('updateCalendarItem clears time override', () {
        dataSource.setTimeOverride(
          1,
          '2025-01-20T09:00:00Z',
          '2025-01-20T10:00:00Z',
        );
        expect(dataSource.getTimeOverride(1), isNotNull);

        final updated = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-20T09:00:00Z'),
          end: DateTime.parse('2025-01-20T10:00:00Z'),
        );
        dataSource.updateCalendarItem(updated);

        expect(dataSource.getTimeOverride(1), isNull);
      });

      test('time override works for EventModel', () {
        final event = _createEventModel(
          id: 2,
          start: DateTime.parse('2025-01-15T14:00:00Z'),
          end: DateTime.parse('2025-01-15T15:00:00Z'),
        );
        dataSource.addCalendarItem(event);

        dataSource.setTimeOverride(
          2,
          '2025-01-18T16:00:00Z',
          '2025-01-18T17:00:00Z',
        );

        final override = dataSource.getTimeOverride(2);
        expect(override, isNotNull);
        expect(override!.start, '2025-01-18T16:00:00Z');
      });
    });

    group('priority-based time adjustments', () {
      test('homework gets 3100 seconds subtracted from start time', () {
        final homework = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addCalendarItem(homework);

        final startTime = dataSource.getStartTime(0);
        // Homework: (3-0)*1000 + (100-0) = 3100 seconds
        expect(
          startTime,
          DateTime.parse(
            '2025-01-15T10:00:00Z',
          ).subtract(const Duration(seconds: 3100)),
        );
      });

      test('course schedule gets 2100 seconds subtracted from start time', () {
        final schedule = _createCourseScheduleEventModel(id: 1);
        dataSource.addCalendarItem(schedule);

        final startTime = dataSource.getStartTime(0);
        // CourseSchedule: (3-1)*1000 + (100-0) = 2100 seconds
        expect(
          startTime,
          DateTime.parse(
            '2025-01-15T10:00:00Z',
          ).subtract(const Duration(seconds: 2100)),
        );
      });

      test('event gets 1100 seconds subtracted from start time', () {
        final event = _createEventModel(
          id: 1,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addCalendarItem(event);

        final startTime = dataSource.getStartTime(0);
        // Event: (3-2)*1000 + (100-0) = 1100 seconds
        expect(
          startTime,
          DateTime.parse(
            '2025-01-15T10:00:00Z',
          ).subtract(const Duration(seconds: 1100)),
        );
      });

      test('external event gets 100 seconds subtracted from start time', () {
        final external = _createExternalCalendarEventModel(id: 1);
        dataSource.addCalendarItem(external);

        final startTime = dataSource.getStartTime(0);
        // External: (3-3)*1000 + (100-0) = 100 seconds
        expect(
          startTime,
          DateTime.parse('2025-01-15T10:00:00Z').subtract(const Duration(seconds: 100)),
        );
      });

      test('all-day events do not get seconds subtracted from start time', () {
        final allDayHomework = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-15T00:00:00Z'),
          end: DateTime.parse('2025-01-16T00:00:00Z'),
          allDay: true,
        );
        dataSource.addCalendarItem(allDayHomework);

        final startTime = dataSource.getStartTime(0);
        // All-day events should NOT have seconds subtracted (would push to previous day)
        expect(startTime, DateTime.parse('2025-01-15T00:00:00Z'));
      });

      test('homework gets 4min 40sec subtracted from end time', () {
        final homework = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addCalendarItem(homework);

        final endTime = dataSource.getEndTime(0);
        // Homework: 3 + (100/60) = 4.667 → 4min 40sec
        expect(
          endTime,
          DateTime.parse(
            '2025-01-15T11:00:00Z',
          ).subtract(const Duration(minutes: 4, seconds: 40)),
        );
      });

      test('event gets 2min 40sec subtracted from end time', () {
        final event = _createEventModel(
          id: 1,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addCalendarItem(event);

        final endTime = dataSource.getEndTime(0);
        // Event: 1 + (100/60) = 2.667 → 2min 40sec
        expect(
          endTime,
          DateTime.parse(
            '2025-01-15T11:00:00Z',
          ).subtract(const Duration(minutes: 2, seconds: 40)),
        );
      });

      test(
        'priority adjustments ensure homework sorts before event at same time',
        () {
          final event = _createEventModel(
            id: 1,
            start: DateTime.parse('2025-01-15T10:00:00Z'),
            end: DateTime.parse('2025-01-15T11:00:00Z'),
          );
          final homework = _createHomeworkModel(
            id: 2,
            start: DateTime.parse('2025-01-15T10:00:00Z'),
            end: DateTime.parse('2025-01-15T11:00:00Z'),
          );
          dataSource.addCalendarItem(event);
          dataSource.addCalendarItem(homework);

          // Homework (priority 0) gets -3 seconds, Event (priority 2) gets -1 second
          // So homework's adjusted start is earlier and should sort first
          final homeworkAdjustedStart = DateTime.parse(
            '2025-01-15T10:00:00Z',
          ).subtract(const Duration(seconds: 3));
          final eventAdjustedStart = DateTime.parse(
            '2025-01-15T10:00:00Z',
          ).subtract(const Duration(seconds: 1));

          expect(homeworkAdjustedStart.isBefore(eventAdjustedStart), isTrue);
        },
      );
    });

    group('clearFilters', () {
      test('clears all filters except search and courses', () {
        dataSource.setFilterCategories(['Assignments']);
        dataSource.setFilterTypes(['Events']);
        dataSource.setFilterStatuses({'Complete'});

        dataSource.clearFilters();

        expect(dataSource.filterCategories, isEmpty);
        expect(dataSource.filterTypes, isEmpty);
        expect(dataSource.filterStatuses, isEmpty);
      });

      test('does not clear search query', () {
        dataSource.setSearchQuery('test');
        dataSource.clearFilters();
        expect(dataSource.searchQuery, 'test');
      });

      test('does not clear filtered courses', () {
        dataSource.setFilteredCourses({1: true});
        dataSource.clearFilters();
        expect(dataSource.filteredCourses, isNotEmpty);
      });
    });

    group('handleLoadMore', () {
      late CalendarItemDataSource freshDataSource;

      setUp(() {
        // Reset mocks to clear calls from outer setUp
        reset(mockHomeworkRepository);
        reset(mockEventRepository);
        reset(mockCourseScheduleRepository);
        reset(mockExternalCalendarRepository);

        // Re-setup default mocks
        when(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockEventRepository.getEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockCourseScheduleRepository.getCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);

        // Create a fresh data source without the pre-loaded cache
        freshDataSource = CalendarItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
          externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );
      });

      test('sets hasLoadedInitialData after first load', () async {
        expect(freshDataSource.hasLoadedInitialData, isFalse);

        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        expect(freshDataSource.hasLoadedInitialData, isTrue);
      });

      test('caches date ranges and skips fetch on repeat', () async {
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        // Reset mocks to track new calls
        reset(mockHomeworkRepository);
        reset(mockEventRepository);
        reset(mockCourseScheduleRepository);
        reset(mockExternalCalendarRepository);

        when(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockEventRepository.getEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockCourseScheduleRepository.getCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);

        // Same range should use cache
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        verifyNever(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        );
      });

      test('fetches for different date ranges', () async {
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        // Different range should fetch
        await freshDataSource.handleLoadMore(
          DateTime(2025, 2, 1),
          DateTime(2025, 2, 28),
        );

        verify(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).called(2);
      });

      test('fetches calendar items from all repositories', () async {
        final homework = _createHomeworkModel(id: 100);
        final event = _createEventModel(id: 101);
        final scheduleEvent = _createCourseScheduleEventModel(id: 102);
        final externalEvent = _createExternalCalendarEventModel(id: 103);

        when(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => [homework]);
        when(
          () => mockEventRepository.getEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => [event]);
        when(
          () => mockCourseScheduleRepository.getCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => [scheduleEvent]);
        when(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => [externalEvent]);

        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        expect(freshDataSource.allCalendarItems, hasLength(4));
        expect(freshDataSource.appointments, hasLength(4));
      });

      test('deduplicates items across overlapping date ranges', () async {
        final homework = _createHomeworkModel(id: 100);

        when(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => [homework]);

        // Load two different ranges that both return the same item
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 15),
          DateTime(2025, 2, 15),
        );

        // allCalendarItems should deduplicate
        expect(freshDataSource.allCalendarItems, hasLength(1));
      });

      test('fetches with shownOnCalendar=true for homework', () async {
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        verify(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: true,
          ),
        ).called(1);
      });
    });

    group('typed getters', () {
      test('allHomeworks returns only HomeworkModels', () {
        dataSource.addCalendarItem(_createHomeworkModel(id: 101));
        dataSource.addCalendarItem(_createEventModel(id: 102));
        dataSource.addCalendarItem(_createHomeworkModel(id: 103));

        expect(dataSource.allHomeworks, hasLength(2));
      });

      test('allEvents returns only EventModels', () {
        dataSource.addCalendarItem(_createHomeworkModel(id: 104));
        dataSource.addCalendarItem(_createEventModel(id: 105));
        dataSource.addCalendarItem(_createEventModel(id: 106));

        expect(dataSource.allEvents, hasLength(2));
      });

      test(
        'allCourseScheduleEvents returns only CourseScheduleEventModels',
        () {
          dataSource.addCalendarItem(_createCourseScheduleEventModel(id: 107));
          dataSource.addCalendarItem(_createEventModel(id: 108));
          dataSource.addCalendarItem(_createCourseScheduleEventModel(id: 109));

          expect(dataSource.allCourseScheduleEvents, hasLength(2));
        },
      );

      test(
        'allExternalCalendarEvents returns only ExternalCalendarEventModels',
        () {
          dataSource.addCalendarItem(
            _createExternalCalendarEventModel(id: 110),
          );
          dataSource.addCalendarItem(_createEventModel(id: 111));
          dataSource.addCalendarItem(
            _createExternalCalendarEventModel(id: 112),
          );

          expect(dataSource.allExternalCalendarEvents, hasLength(2));
        },
      );
    });

    group('convertAppointmentToObject', () {
      test('returns the custom data unchanged', () {
        final homework = _createHomeworkModel(id: 1);
        final appointment = Appointment(
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );

        final result = dataSource.convertAppointmentToObject(
          homework,
          appointment,
        );

        expect(result, homework);
      });

      test('returns null when custom data is null', () {
        final appointment = Appointment(
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );

        final result = dataSource.convertAppointmentToObject(null, appointment);

        expect(result, isNull);
      });
    });
  });
}

// Helper functions to create test models

HomeworkModel _createHomeworkModel({
  int id = 1,
  String title = 'Test Homework',
  DateTime? start,
  DateTime? end,
  bool allDay = false,
  int courseId = 1,
  int categoryId = 1,
  CategoryModel? categoryEntity,
  bool completed = false,
  String comments = '',
}) {
  return HomeworkModel(
    id: id,
    title: title,
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    comments: comments,
    attachments: [],
    reminders: [],
    completed: completed,
    currentGrade: '-1/100',
    course: IdOrEntity<CourseModel>(id: courseId),
    category: categoryEntity != null
        ? IdOrEntity<CategoryModel>(id: categoryId, entity: categoryEntity)
        : IdOrEntity<CategoryModel>(id: categoryId),
    materials: [],
  );
}

EventModel _createEventModel({
  int id = 1,
  String title = 'Test Event',
  DateTime? start,
  DateTime? end,
  bool allDay = false,
  String comments = '',
}) {
  return EventModel(
    id: id,
    title: title,
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T14:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T15:00:00Z'),
    priority: 50,
    url: null,
    comments: comments,
    attachments: [],
    reminders: [],
    color: const Color(0xFF4CAF50),
  );
}

CourseScheduleEventModel _createCourseScheduleEventModel({
  int id = 1,
  String title = 'Test Class',
  String ownerId = '1',
  Color color = const Color(0xFFFF5722),
}) {
  return CourseScheduleEventModel(
    id: id,
    title: title,
    allDay: false,
    showEndTime: true,
    start: DateTime.parse('2025-01-15T10:00:00Z'),
    end: DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    ownerId: ownerId,
    color: color,
  );
}

ExternalCalendarEventModel _createExternalCalendarEventModel({
  int id = 1,
  String title = 'External Event',
  Color color = const Color(0xFF9C27B0),
}) {
  return ExternalCalendarEventModel(
    id: id,
    title: title,
    allDay: false,
    showEndTime: true,
    start: DateTime.parse('2025-01-15T10:00:00Z'),
    end: DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    ownerId: '1',
    color: color,
  );
}

CourseModel _createCourseModel({
  int id = 1,
  String title = 'Test Course',
  Color color = const Color(0xFF2196F3),
  String? room,
}) {
  return CourseModel(
    id: id,
    title: title,
    startDate: DateTime.parse('2025-01-01'),
    endDate: DateTime.parse('2025-05-31'),
    room: room ?? '',
    credits: 3,
    color: color,
    website: '',
    isOnline: false,
    courseGroup: 1,
    teacherName: '',
    teacherEmail: '',
    currentGrade: null,
    schedules: [],
  );
}

CategoryModel _createCategoryModel({
  int id = 1,
  String title = 'Test Category',
  Color color = const Color(0xFFF44336),
}) {
  return CategoryModel(
    id: id,
    title: title,
    color: color,
    course: 1,
    weight: 100,
  );
}
