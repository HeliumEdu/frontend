import '../../mocks/mock_models.dart';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
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
    group('Todos window', () {
      for (final zoneName in ['Europe/Amsterdam', 'America/Los_Angeles']) {
        test('lists assignments overlapping a group and hides those after every group ends ($zoneName)', () {
          // GIVEN
          final zone = tz.getLocation(zoneName);
          dataSource.userSettings = _createUserSettings(timeZone: zone);
          dataSource.courseGroupsById = {
            1: MockModels.createCourseGroup(
              startDate: DateTime(2025, 8, 25),
              endDate: DateTime(2025, 12, 15),
            ),
          };
          dataSource.addPlannerItem(MockModels.createHomework(
            id: 1,
            start: tz.TZDateTime(zone, 2025, 10, 1, 9).toUtc(),
            end: tz.TZDateTime(zone, 2025, 10, 1, 10).toUtc(),
          ));
          dataSource.addPlannerItem(MockModels.createHomework(
            id: 2,
            start: tz.TZDateTime(zone, 2025, 12, 15, 23).toUtc(),
            end: tz.TZDateTime(zone, 2025, 12, 16, 1).toUtc(),
          ));
          dataSource.addPlannerItem(MockModels.createHomework(
            id: 3,
            start: tz.TZDateTime(zone, 2025, 12, 16, 0, 30).toUtc(),
            end: tz.TZDateTime(zone, 2025, 12, 16, 1).toUtc(),
          ));

          // WHEN
          final listed = dataSource.filteredHomeworks;

          // THEN
          expect(
            listed.map((h) => h.id),
            unorderedEquals([1, 2]),
            reason: 'one starting on the last day still shows; one entirely after it does not',
          );
        });
      }

      test('lists the occurrences of a repeating assignment inside a group, not those after it ends', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
        dataSource.courseGroupsById = {
          1: MockModels.createCourseGroup(
            startDate: DateTime(2025, 8, 25),
            endDate: DateTime(2025, 9, 20),
          ),
        };
        dataSource.addPlannerItem(MockModels.createHomework(
          id: 950,
          start: tz.TZDateTime(amsterdam, 2025, 9, 11, 9).toUtc(),
          end: tz.TZDateTime(amsterdam, 2025, 9, 11, 10).toUtc(),
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;COUNT=4',
        ));

        // WHEN
        final listed = dataSource.filteredHomeworks;

        // THEN
        expect(
          listed.map((h) => tz.TZDateTime.from(h.start, amsterdam).day),
          [11, 18],
        );
      });

      test('lists every assignment before the groups have loaded', () {
        // GIVEN
        dataSource.courseGroupsById = null;
        dataSource.addPlannerItem(_createHomeworkModel(id: 1));

        // WHEN
        final listed = dataSource.filteredHomeworks;

        // THEN
        expect(listed.map((h) => h.id), [1]);
      });
    });

    group('repeating assignments', () {
      late tz.Location amsterdam;
      late HomeworkModel series;

      setUp(() {
        amsterdam = tz.getLocation('Europe/Amsterdam');
        dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
        series = MockModels.createHomework(
          id: 950,
          start: tz.TZDateTime(amsterdam, 2025, 9, 11, 23, 30).toUtc(),
          end: tz.TZDateTime(amsterdam, 2025, 9, 11, 23, 30).toUtc(),
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;COUNT=4',
          exceptionDates: [tz.TZDateTime(amsterdam, 2025, 9, 18, 23, 30).toUtc()],
        );
      });

      test('the Todos list shows each occurrence at its own start, skipping exception dates', () {
        // GIVEN
        dataSource.addPlannerItem(series);

        // WHEN
        final occurrences = dataSource.filteredHomeworks;

        // THEN
        expect(
          occurrences.map((h) => tz.TZDateTime.from(h.start, amsterdam).toString()),
          [
            tz.TZDateTime(amsterdam, 2025, 9, 11, 23, 30).toString(),
            tz.TZDateTime(amsterdam, 2025, 9, 25, 23, 30).toString(),
            tz.TZDateTime(amsterdam, 2025, 10, 2, 23, 30).toString(),
          ],
          reason: 'the 18th is an exception date, and late-night occurrences stay on their local day',
        );
        expect(occurrences.map((h) => h.id).toSet(), {950});
        expect(occurrences.every((h) => h.recurrenceRule == series.recurrenceRule), isTrue);
      });

      test('the calendar keeps the series as one item for SfCalendar to expand', () {
        // GIVEN
        dataSource.addPlannerItem(series);

        // WHEN
        final index = dataSource.appointments!.indexOf(series);

        // THEN
        expect(dataSource.appointments!.whereType<HomeworkModel>(), hasLength(1));
        expect(dataSource.getRecurrenceRule(index), startsWith('FREQ=WEEKLY;BYDAY=TH'));
        expect(dataSource.getRecurrenceExceptionDates(index), series.exceptionDates);
      });

      test('the day list shows an occurrence on its day but not on an exception date', () {
        // GIVEN
        dataSource.addPlannerItem(series);

        // WHEN
        final onOccurrence = dataSource.getItemsForDay(DateTime(2025, 9, 25));
        final onException = dataSource.getItemsForDay(DateTime(2025, 9, 18));

        // THEN
        final occurrence = onOccurrence.whereType<HomeworkModel>().single;
        expect(occurrence.start, tz.TZDateTime(amsterdam, 2025, 9, 25, 23, 30));
        expect(dataSource.isHomeworkCompleted(occurrence), isFalse);
        expect(onException.whereType<HomeworkModel>(), isEmpty);
      });
    });

    group('assignments due at midnight', () {
      for (final zoneName in ['Europe/Amsterdam', 'America/Los_Angeles']) {
        test('render on their due date, not the day before ($zoneName)', () {
          // GIVEN
          final zone = tz.getLocation(zoneName);
          dataSource.userSettings = _createUserSettings(timeZone: zone);
          final dueAtMidnight = tz.TZDateTime(zone, 2026, 11, 1);
          dataSource.appointments!.insert(
            0,
            _createHomeworkModel(id: 40, start: dueAtMidnight, end: dueAtMidnight),
          );

          // WHEN
          final start = tz.TZDateTime.from(dataSource.getStartTime(0), zone);
          final end = tz.TZDateTime.from(dataSource.getEndTime(0), zone);

          // THEN
          expect(DateTime(start.year, start.month, start.day), DateTime(2026, 11, 1));
          expect(DateTime(end.year, end.month, end.day), DateTime(2026, 11, 1));
          expect(end.isBefore(start), isFalse);
        });

        test('count toward their due date ($zoneName)', () {
          // GIVEN
          final zone = tz.getLocation(zoneName);
          dataSource.userSettings = _createUserSettings(timeZone: zone);
          final dueAtMidnight = tz.TZDateTime(zone, 2026, 11, 1);
          dataSource.addPlannerItem(
            _createHomeworkModel(id: 41, start: dueAtMidnight, end: dueAtMidnight),
          );

          // WHEN
          final items = dataSource.getItemsForDay(DateTime(2026, 11, 1));

          // THEN
          expect(items.map((item) => item.id), contains(41));
        });
      }

      test('sort before items due a minute later', () {
        // GIVEN
        final zone = userSettings.timeZone;
        final midnight = tz.TZDateTime(zone, 2026, 11, 1);
        final aMinuteLater = tz.TZDateTime(zone, 2026, 11, 1, 0, 1);
        dataSource.appointments!.insert(0, _createEventModel(id: 50, start: aMinuteLater, end: aMinuteLater));
        dataSource.appointments!.insert(0, _createHomeworkModel(id: 52, start: midnight, end: midnight));

        // WHEN
        final midnightStart = dataSource.getStartTime(0);
        final aMinuteLaterStart = dataSource.getStartTime(1);

        // THEN
        expect(midnightStart.isBefore(aMinuteLaterStart), isTrue);
      });
    });

    group('currentTimesOf', () {
      test('reflects a resize SfCalendar has not handed back yet', () {
        // GIVEN
        final rendered = _createHomeworkModel(
          id: 60,
          allDay: true,
          start: DateTime.parse('2026-11-17T06:00:00Z'),
          end: DateTime.parse('2026-11-18T06:00:00Z'),
        );
        dataSource.addPlannerItem(rendered);
        dataSource.setTimeOverride(rendered, '2026-11-17T06:00:00Z', '2026-11-21T06:00:00Z');

        // WHEN
        final (start, end) = dataSource.currentTimesOf(rendered);

        // THEN
        expect(start, DateTime.parse('2026-11-17T06:00:00Z'));
        expect(end, DateTime.parse('2026-11-21T06:00:00Z'));
      });

      test('reflects a saved copy newer than the one SfCalendar rendered', () {
        // GIVEN
        final rendered = _createHomeworkModel(
          id: 61,
          allDay: true,
          start: DateTime.parse('2026-11-17T06:00:00Z'),
          end: DateTime.parse('2026-11-18T06:00:00Z'),
        );
        dataSource.addPlannerItem(rendered);
        dataSource.updatePlannerItem(_createHomeworkModel(
          id: 61,
          allDay: true,
          start: DateTime.parse('2026-11-17T06:00:00Z'),
          end: DateTime.parse('2026-11-21T06:00:00Z'),
        ));

        // WHEN
        final (_, end) = dataSource.currentTimesOf(rendered);

        // THEN
        expect(end, DateTime.parse('2026-11-21T06:00:00Z'));
      });
    });

    group('day queries', () {
      test('counts only the given course\'s meetings on a day', () {
        // GIVEN
        final course = _createCourseModel(id: 1);
        dataSource.addPlannerItem(
          _createCourseScheduleEventModel(id: 1, ownerId: '1'),
        );
        dataSource.addPlannerItem(
          _createCourseScheduleEventModel(id: 2, ownerId: '1'),
        );
        dataSource.addPlannerItem(
          _createCourseScheduleEventModel(id: 3, ownerId: '2'),
        );

        // WHEN
        final onDay = dataSource.courseMeetingCountOn(
          course,
          DateTime(2025, 1, 15),
        );
        final nextDay = dataSource.courseMeetingCountOn(
          course,
          DateTime(2025, 1, 16),
        );

        // THEN
        expect(onDay, 2);
        expect(nextDay, 0);
      });

      test('resolves a repeating item to its occurrence on the day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
        final series = MockModels.createHomework(
          id: 960,
          start: tz.TZDateTime(amsterdam, 2025, 9, 11, 23, 30).toUtc(),
          end: tz.TZDateTime(amsterdam, 2025, 9, 11, 23, 30).toUtc(),
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;COUNT=4',
        );
        dataSource.addPlannerItem(series);

        // WHEN
        final occurrence = dataSource.occurrenceOn(
          series,
          DateTime(2025, 9, 25),
        );

        // THEN
        expect(occurrence, isNotNull);
        expect(
          tz.TZDateTime.from(occurrence!.start, amsterdam).toString(),
          tz.TZDateTime(amsterdam, 2025, 9, 25, 23, 30).toString(),
          reason: 'the late-night occurrence stays on its local day',
        );
      });

      test('finds no occurrence on a day the item is not on', () {
        // GIVEN
        final homework = _createHomeworkModel(id: 1);
        dataSource.addPlannerItem(homework);

        // WHEN
        final occurrence = dataSource.occurrenceOn(
          homework,
          DateTime(2025, 2, 1),
        );

        // THEN
        expect(occurrence, isNull);
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
    language: 'en',
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
