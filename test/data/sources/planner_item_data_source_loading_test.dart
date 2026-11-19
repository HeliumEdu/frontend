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
    );

    await dataSource.handleLoadMore(
      DateTime(2024, 1, 1),
      DateTime(2026, 12, 31),
    );
  });

  group('PlannerItemDataSource', () {
    group('refreshCalendarSources', () {
      late PlannerItemDataSource freshDataSource;

      void stubEmptySources() {
        when(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockEventRepository.getEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            forceRefresh: any(named: 'forceRefresh'),
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
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => []);
      }

      setUp(() {
        reset(mockHomeworkRepository);
        reset(mockEventRepository);
        reset(mockCourseScheduleRepository);
        reset(mockExternalCalendarRepository);
        stubEmptySources();

        freshDataSource = PlannerItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
              externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );
      });

      test('refetches an already-cached range the range cache would skip', () async {
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        reset(mockHomeworkRepository);
        reset(mockEventRepository);
        reset(mockCourseScheduleRepository);
        reset(mockExternalCalendarRepository);
        stubEmptySources();

        await freshDataSource.refreshCalendarSources(
          visibleStart: DateTime(2025, 1, 1),
          visibleEnd: DateTime(2025, 1, 31),
        );

        verify(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).called(1);
        verify(
          () => mockEventRepository.getEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).called(1);
        verify(
          () => mockCourseScheduleRepository.getCourseScheduleEvents(
            courses: any(named: 'courses'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).called(1);
        verify(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).called(1);
      });

    });

    group('handleLoadMore', () {
      late PlannerItemDataSource freshDataSource;

      setUp(() {
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
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);

        freshDataSource = PlannerItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
              externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );
      });


      test('caches date ranges and skips fetch on repeat', () async {
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

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
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: any(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).thenAnswer((_) async => []);

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

      test('fetches through the end of the last requested day', () async {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');

        // WHEN
        await freshDataSource.handleLoadMore(
          DateTime(2025, 3, 1),
          DateTime(2025, 3, 7),
        );

        // THEN
        final homeworkTo = verify(
          () => mockHomeworkRepository.getHomeworks(
            from: any(named: 'from'),
            to: captureAny(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).captured.single as DateTime;
        expect(homeworkTo, tz.TZDateTime(la, 2025, 3, 8));
        final eventTo = verify(
          () => mockEventRepository.getEvents(
            from: any(named: 'from'),
            to: captureAny(named: 'to'),
          ),
        ).captured.single as DateTime;
        expect(eventTo, tz.TZDateTime(la, 2025, 3, 8));
        final externalTo = verify(
          () => mockExternalCalendarRepository.getExternalCalendarEvents(
            from: any(named: 'from'),
            to: captureAny(named: 'to'),
            shownOnCalendar: any(named: 'shownOnCalendar'),
          ),
        ).captured.single as DateTime;
        expect(externalTo, tz.TZDateTime(la, 2025, 3, 8));
      });

      test('keeps an item added on the last loaded day', () async {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        await freshDataSource.handleLoadMore(
          DateTime(2025, 3, 1),
          DateTime(2025, 3, 7),
        );
        final homework = _createHomeworkModel(
          id: 77,
          start: tz.TZDateTime(la, 2025, 3, 7, 10).toUtc(),
          end: tz.TZDateTime(la, 2025, 3, 7, 11).toUtc(),
        );

        // WHEN
        freshDataSource.addPlannerItem(homework);

        // THEN
        expect(
          freshDataSource.allPlannerItems.whereType<HomeworkModel>().map((h) => h.id),
          contains(77),
        );
      });

      test('fetches for different date ranges', () async {
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

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

        expect(freshDataSource.allPlannerItems, hasLength(4));
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

        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );
        await freshDataSource.handleLoadMore(
          DateTime(2025, 1, 15),
          DateTime(2025, 2, 15),
        );

        expect(freshDataSource.allPlannerItems, hasLength(1));
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
