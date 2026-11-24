import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/standalone.dart' as tz;

class MockEventRepository extends Mock implements EventRepository {}

class MockHomeworkRepository extends Mock implements HomeworkRepository {}

class MockCourseScheduleRepository extends Mock
    implements CourseScheduleRepository {}

class MockExternalCalendarRepository extends Mock
    implements ExternalCalendarRepository {}

void main() {
  late PlannerItemDataSource dataSource;
  late MockEventRepository mockEventRepository;
  late MockHomeworkRepository mockHomeworkRepository;
  late MockCourseScheduleRepository mockCourseScheduleRepository;
  late MockExternalCalendarRepository mockExternalCalendarRepository;
  late UserSettingsModel userSettings;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    PlannerItemDataSource.filterDebounceDuration = Duration.zero;
  });

  tearDownAll(() {
    PlannerItemDataSource.filterDebounceDuration = const Duration(
      milliseconds: 16,
    );
  });

  setUp(() async {
    mockEventRepository = MockEventRepository();
    mockHomeworkRepository = MockHomeworkRepository();
    mockCourseScheduleRepository = MockCourseScheduleRepository();
    mockExternalCalendarRepository = MockExternalCalendarRepository();

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
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockExternalCalendarRepository.getExternalCalendarEvents(
        from: any(named: 'from'),
        to: any(named: 'to'),
        shownOnCalendar: any(named: 'shownOnCalendar'),
      ),
    ).thenAnswer((_) async => []);

    userSettings = _createUserSettings(
      timeZone: tz.getLocation('America/Los_Angeles'),
    );

    dataSource = PlannerItemDataSource(
      eventRepository: mockEventRepository,
      homeworkRepository: mockHomeworkRepository,
      courseScheduleRepository: mockCourseScheduleRepository,
      externalCalendarRepository: mockExternalCalendarRepository,
      userSettings: userSettings,
      todosItemsPerPage: 10,
    );

    await dataSource.handleLoadMore(
      DateTime(2024, 1, 1),
      DateTime(2026, 12, 31),
    );
  });

  group('PlannerItemDataSource', () {
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
        dataSource.addPlannerItem(homework1);
        dataSource.addPlannerItem(homework2);
        dataSource.addPlannerItem(homework3);
      });

      test('returns all homeworks when no courses selected', () {
        dataSource.setSelectedCourses({});
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters by single selected course', () {
        dataSource.setSelectedCourses({1: true});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });

      test('filters by multiple selected courses', () {
        dataSource.setSelectedCourses({1: true, 2: true});
        expect(dataSource.filteredHomeworks, hasLength(3));
      });

      test('filters out when course not selected', () {
        dataSource.setSelectedCourses({1: true, 2: false});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(2));
        expect(filtered.map((h) => h.id), containsAll([1, 3]));
      });

      test('filters by course ID', () {
        dataSource.setSelectedCourses({1: true});
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
        dataSource.addPlannerItem(scheduleEvent1);
        dataSource.addPlannerItem(scheduleEvent2);

        dataSource.setSelectedCourses({1: true});
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
        dataSource.addPlannerItem(homework1);
        dataSource.addPlannerItem(homework2);
        dataSource.addPlannerItem(homework3);
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
        dataSource.addPlannerItem(homeworkWithEntity);

        dataSource.setFilterCategories(['Assignments']);
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(3));
        expect(filtered.map((h) => h.id), containsAll([1, 3, 4]));
      });

      test('excludes homework with empty category title', () {
        final emptyCategory = _createCategoryModel(id: 3, title: '  ');
        final homework = _createHomeworkModel(id: 5, categoryId: 3);
        dataSource.categoriesMap![3] = emptyCategory;
        dataSource.addPlannerItem(homework);

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

        dataSource.addPlannerItem(completedHomework);
        dataSource.addPlannerItem(incompleteHomework);
        dataSource.addPlannerItem(overdueHomework);
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
        dataSource.addPlannerItem(completedOverdue);

        dataSource.setFilterStatuses({'Overdue'});
        final filtered = dataSource.filteredHomeworks;

        expect(filtered, hasLength(1));
        expect(filtered[0].id, 3);
      });

      test('respects completed overrides in status filter', () {
        dataSource.setCompletedOverride(2, true);
        dataSource.setFilterStatuses({'Complete'});
        final filtered = dataSource.filteredHomeworks;

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
          notesText: 'Complete problems 1-10',
        );
        homework2 = _createHomeworkModel(
          id: 2,
          title: 'Physics Lab Report',
          notesText: 'Write conclusions',
        );
        event1 = _createEventModel(
          id: 3,
          title: 'Study Session',
          notesText: 'Review math notes',
        );

        dataSource.addPlannerItem(homework1);
        dataSource.addPlannerItem(homework2);
        dataSource.addPlannerItem(event1);
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

        dataSource.addPlannerItem(homework);
        dataSource.addPlannerItem(event);
        dataSource.addPlannerItem(scheduleEvent);
        dataSource.addPlannerItem(externalEvent);
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
        dataSource.addPlannerItem(matchingHomework);
        dataSource.addPlannerItem(nonMatchingCourse);
        dataSource.addPlannerItem(nonMatchingCategory);
      });

      test('applies course and category filters together', () {
        dataSource.setSelectedCourses({1: true});
        dataSource.setFilterCategories(['Assignments']);

        final filtered = dataSource.filteredHomeworks;
        expect(filtered, hasLength(1));
        expect(filtered[0].id, 1);
      });

      test('applies all filters together', () {
        dataSource.setSelectedCourses({1: true});
        dataSource.setFilterCategories(['Assignments']);
        dataSource.setFilterStatuses({'Incomplete'});
        dataSource.setSearchQuery('Math');

        final filtered = dataSource.filteredHomeworks;
        expect(filtered, hasLength(1));
        expect(filtered[0].id, 1);
      });

      test('returns empty when filters exclude all items', () {
        dataSource.setSelectedCourses({1: true});
        dataSource.setSearchQuery('Physics');

        expect(dataSource.filteredHomeworks, isEmpty);
      });
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

      test('clears filtered courses', () {
        dataSource.setSelectedCourses({1: true});
        dataSource.clearFilters();
        expect(dataSource.selectedCourses, isEmpty);
      });
    });
  });
}

UserSettingsModel _createUserSettings({required tz.Location timeZone}) {
  return UserSettingsModel(
    timeZone: timeZone,
    defaultView: 0,
    colorSchemeTheme: 0,
    weekStartsOn: 0,
    whatsNewVersionSeen: 0,
    showGettingStarted: false,
    gettingStartedDue: false,
    eventsColor: const Color(0xFF4CAF50),
    resourceColor: const Color(0xFF2196F3),
    gradeColor: const Color(0xFFF44336),
    defaultReminderType: 3,
    defaultReminderOffset: 0,
    defaultReminderOffsetType: 0,
    colorByCategory: false,
    showPlannerTooltips: true,
    rememberFilterState: false,
    collapseBusyDays: true,
    setupState: SetupState.complete,
    dragAndDropOnMobile: true,
    atRiskThreshold: 70,
    showWeekNumbers: false,
    dateFormat: 0,
    timeFormat: 0,
    numberFormat: 0,
    onTrackTolerance: 10,
    priorCredits: 0,
    priorGpa: 0,
    promptForReview: false,
  );
}

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
  String? notesText,
}) {
  return HomeworkModel(
    id: id,
    courseGroup: 1,
    title: title,
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    attachments: [],
    reminders: [],
    notes: [],
    completed: completed,
    currentGrade: '-1/100',
    course: IdOrEntity<CourseModel>(id: courseId),
    category: categoryEntity != null
        ? IdOrEntity<CategoryModel>(id: categoryId, entity: categoryEntity)
        : IdOrEntity<CategoryModel>(id: categoryId),
    resources: [],
  );
}

EventModel _createEventModel({
  int id = 1,
  String title = 'Test Event',
  DateTime? start,
  DateTime? end,
  bool allDay = false,
  String? notesText,
}) {
  return EventModel(
    id: id,
    title: title,
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T14:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T15:00:00Z'),
    priority: 50,
    attachments: [],
    reminders: [],
    notes: [],
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
    exceptionDates: const [],
  );
}

ExternalCalendarEventModel _createExternalCalendarEventModel({
  int id = 1,
  String title = 'External Event',
  Color color = const Color(0xFF9C27B0),
  DateTime? start,
  DateTime? end,
  String? recurrenceRule,
  List<DateTime> exceptionDates = const [],
  bool allDay = false,
}) {
  return ExternalCalendarEventModel(
    id: id,
    title: title,
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    ownerId: '1',
    color: color,
    recurrenceRule: recurrenceRule,
    exceptionDates: exceptionDates,
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
    website: null,
    isOnline: false,
    courseGroup: 1,
    teacherName: '',
    teacherEmail: '',
    currentGrade: null,
    schedules: [],
    exceptions: const [],
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
    courseGroup: 1,
    weight: 100,
  );
}
