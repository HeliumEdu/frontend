import '../../mocks/mock_models.dart';
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
import 'package:syncfusion_flutter_calendar/calendar.dart';
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
    group('visibleResourcesFor', () {
      test('lists only resources the planner shows, by title', () {
        // GIVEN
        dataSource.resourcesMap = {
          20: MockModels.createResource(id: 20, title: 'Textbook'),
          21: MockModels.createResource(id: 21, title: 'Lab Manual'),
        };
        final homework = MockModels.createHomework(id: 1, resourceIds: [20, 21, 22]);

        // WHEN
        final resources = dataSource.visibleResourcesFor(homework);

        // THEN
        expect(resources.map((r) => r.title), ['Lab Manual', 'Textbook'],
            reason: 'resource 22 is in a hidden group, so the planner never loaded it');
      });
    });

    group('initialization', () {
      test('initializes with empty appointments', () {
        final freshDataSource = PlannerItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
              externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );

        expect(freshDataSource.appointments, isEmpty);
        expect(freshDataSource.allPlannerItems, isEmpty);
      });

      test('initializes with empty filter state', () {
        final freshDataSource = PlannerItemDataSource(
          eventRepository: mockEventRepository,
          homeworkRepository: mockHomeworkRepository,
          courseScheduleRepository: mockCourseScheduleRepository,
              externalCalendarRepository: mockExternalCalendarRepository,
          userSettings: userSettings,
        );

        expect(freshDataSource.selectedCourses, isEmpty);
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

        dataSource.addPlannerItem(homework);
        dataSource.addPlannerItem(event);
      });

      test('getStartTime returns DateTime with priority adjustment', () {
        final startTime = dataSource.getStartTime(0);
        final expectedBase = tz.TZDateTime.from(
          DateTime.parse('2025-01-15T10:00:00Z'),
          userSettings.timeZone,
        );
        expect(
          startTime,
          expectedBase.subtract(const Duration(seconds: 103)),
        );
      });

      test(
        'getEndTime returns DateTime with priority adjustment for non-allDay events',
        () {
          final endTime = dataSource.getEndTime(0);
          final expectedBase = tz.TZDateTime.from(
            DateTime.parse('2025-01-15T11:00:00Z'),
            userSettings.timeZone,
          );
          expect(
            endTime,
            expectedBase.subtract(const Duration(seconds: 103)),
          );
        },
      );

      test('getEndTime subtracts 1 day for allDay events', () {
        final allDayHomework = _createHomeworkModel(
          id: 3,
          title: 'All Day',
          start: DateTime.parse('2025-01-15T08:00:00Z'),
          end: DateTime.parse('2025-01-16T08:00:00Z'),
          allDay: true,
        );
        dataSource.appointments!.insert(0, allDayHomework);

        final endTime = dataSource.getEndTime(0);
        final expected = tz.TZDateTime(userSettings.timeZone, 2025, 1, 15);
        expect(endTime, expected);
      });

      test(
        'all-day item at a positive UTC offset anchors on the user-local date',
        () {
          final amsterdam = tz.getLocation('Europe/Amsterdam');
          dataSource.userSettings = _createUserSettings(timeZone: amsterdam);

          final allDayHomework = _createHomeworkModel(
            id: 4,
            title: 'Amsterdam All Day',
            start: DateTime.parse('2025-09-03T22:00:00Z'),
            end: DateTime.parse('2025-09-04T22:00:00Z'),
            allDay: true,
          );
          dataSource.appointments!.insert(0, allDayHomework);

          expect(
            dataSource.getStartTime(0),
            tz.TZDateTime(amsterdam, 2025, 9, 4),
          );
          expect(
            dataSource.getEndTime(0),
            tz.TZDateTime(amsterdam, 2025, 9, 4),
          );
          expect(dataSource.isAllDay(0), isTrue);

          DateTime asRendered(DateTime value) {
            final converted = tz.TZDateTime.from(value, amsterdam);
            return DateTime(converted.year, converted.month, converted.day);
          }

          expect(asRendered(dataSource.getStartTime(0)), DateTime(2025, 9, 4));
          expect(asRendered(dataSource.getEndTime(0)), DateTime(2025, 9, 4));
        },
      );

      test(
        'a recurring occurrence resolves to the same day the grid renders it',
        () {
          final amsterdam = tz.getLocation('Europe/Amsterdam');
          dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
          dataSource.appointments!.clear();

          dataSource.addPlannerItem(
            CourseScheduleEventModel(
              id: 900,
              title: 'Late Seminar',
              allDay: false,
              showEndTime: true,
              start: DateTime.parse('2025-09-10T22:30:00Z'),
              end: DateTime.parse('2025-09-10T23:30:00Z'),
              priority: 50,
              url: null,
              comments: '',
              attachments: [],
              reminders: [],
              ownerId: '1',
              color: const Color(0xFFFF5722),
              recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;UNTIL=20251009T000000Z',
              exceptionDates: const [],
            ),
          );

          final onOccurrence = dataSource.getItemsForDay(
            DateTime(2025, 9, 18),
          );
          expect(
            onOccurrence.map((e) => e.id),
            contains(900),
            reason: 'the 18th is a local Thursday occurrence',
          );

          final offOccurrence = dataSource.getItemsForDay(
            DateTime(2025, 9, 19),
          );
          expect(
            offOccurrence.map((e) => e.id),
            isNot(contains(900)),
            reason: 'the 19th is only an occurrence in the UTC frame',
          );

          final occurrence = onOccurrence.firstWhere((e) => e.id == 900);
          final localStart = tz.TZDateTime.from(occurrence.start, amsterdam);
          expect(localStart.hour, 0);
          expect(localStart.minute, 30);
        },
      );

      test(
        'an EXDATE suppresses its occurrence through SfCalendar\'s pipeline',
        () {
          final amsterdam = tz.getLocation('Europe/Amsterdam');
          dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
          dataSource.appointments!.clear();

          dataSource.appointments!.insert(
            0,
            _createExternalCalendarEventModel(
              id: 901,
              start: DateTime.parse('2025-09-04T07:00:00Z'),
              end: DateTime.parse('2025-09-04T08:00:00Z'),
              recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;UNTIL=20251002T000000Z',
              exceptionDates: [DateTime.parse('2025-09-18T07:00:00Z')],
            ),
          );

          final occurrences = SfCalendar.getRecurrenceDateTimeCollection(
            dataSource.getRecurrenceRule(0)!,
            _sfCalendarDateTime(dataSource.getStartTime(0), dataSource.userSettings.timeZone),
          );
          final exceptions =
              dataSource.getRecurrenceExceptionDates(0)!
                  .map((e) => _sfCalendarDateTime(e, dataSource.userSettings.timeZone))
                  .toList();

          final rendered = occurrences
              .where((o) => !exceptions.any((e) => _isSameDate(o, e)))
              .map((o) => '${o.year}-${o.month}-${o.day}')
              .toList();

          expect(rendered, contains('2025-9-11'));
          expect(rendered, contains('2025-9-25'));
          expect(
            rendered,
            isNot(contains('2025-9-18')),
            reason: 'the EXDATE must suppress the 18th',
          );
        },
      );

      test(
        'an all-day date-only EXDATE suppresses its own date west of UTC',
        () {
          // GIVEN
          final la = tz.getLocation('America/Los_Angeles');
          dataSource.userSettings = _createUserSettings(timeZone: la);
          dataSource.appointments!.clear();
          dataSource.appointments!.insert(
            0,
            _createExternalCalendarEventModel(
              id: 902,
              allDay: true,
              start: tz.TZDateTime(la, 2025, 10, 1).toUtc(),
              end: tz.TZDateTime(la, 2025, 10, 2).toUtc(),
              recurrenceRule: 'FREQ=DAILY;COUNT=7',
              exceptionDates: [DateTime.parse('2025-10-05T00:00:00Z')],
            ),
          );

          // WHEN
          final occurrences = SfCalendar.getRecurrenceDateTimeCollection(
            dataSource.getRecurrenceRule(0)!,
            _sfCalendarDateTime(dataSource.getStartTime(0), dataSource.userSettings.timeZone),
          );
          final exceptions =
              dataSource.getRecurrenceExceptionDates(0)!
                  .map((e) => _sfCalendarDateTime(e, dataSource.userSettings.timeZone))
                  .toList();
          final rendered = occurrences
              .where((o) => !exceptions.any((e) => _isSameDate(o, e)))
              .map((o) => '${o.year}-${o.month}-${o.day}')
              .toList();

          // THEN
          expect(rendered, isNot(contains('2025-10-5')),
              reason: 'the date-only EXDATE must suppress the 5th');
          expect(rendered, contains('2025-10-4'),
              reason: 'the day before must still show');
        },
      );

      test(
        'an all-day date-only EXDATE suppresses its own date in the day popout west of UTC',
        () {
          // GIVEN
          final la = tz.getLocation('America/Los_Angeles');
          dataSource.userSettings = _createUserSettings(timeZone: la);
          dataSource.appointments!.clear();
          dataSource.appointments!.insert(
            0,
            _createExternalCalendarEventModel(
              id: 903,
              allDay: true,
              start: tz.TZDateTime(la, 2025, 10, 1).toUtc(),
              end: tz.TZDateTime(la, 2025, 10, 2).toUtc(),
              recurrenceRule: 'FREQ=DAILY;COUNT=7',
              exceptionDates: [DateTime.parse('2025-10-05T00:00:00Z')],
            ),
          );

          // WHEN
          final onException = dataSource.getItemsForDay(DateTime(2025, 10, 5));
          final dayBefore = dataSource.getItemsForDay(DateTime(2025, 10, 4));

          // THEN
          expect(onException.map((e) => e.id), isNot(contains(903)),
              reason: 'the date-only EXDATE must suppress the 5th');
          expect(dayBefore.map((e) => e.id), contains(903),
              reason: 'the day before must still show');
        },
      );

      test(
        'a UTC EXDATE suppresses its occurrence in the day list',
        () {
          final amsterdam = tz.getLocation('Europe/Amsterdam');
          dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
          dataSource.appointments!.clear();
          dataSource.appointments!.insert(
            0,
            _createExternalCalendarEventModel(
              id: 902,
              start: DateTime.parse('2025-09-10T22:30:00Z'),
              end: DateTime.parse('2025-09-10T23:30:00Z'),
              recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;UNTIL=20251009T000000Z',
              exceptionDates: [DateTime.parse('2025-09-17T22:30:00Z')],
            ),
          );

          expect(
            dataSource.getItemsForDay(DateTime(2025, 9, 11)).map((e) => e.id),
            contains(902),
          );
          expect(
            dataSource.getItemsForDay(DateTime(2025, 9, 18)).map((e) => e.id),
            isNot(contains(902)),
            reason: 'the EXDATE lands on the 18th once resolved to Amsterdam',
          );
        },
      );

      test(
        'an all-day item ending across a DST transition ends at local midnight',
        () {
          final amsterdam = tz.getLocation('Europe/Amsterdam');
          dataSource.userSettings = _createUserSettings(timeZone: amsterdam);
          dataSource.appointments!.insert(
            0,
            _createHomeworkModel(
              id: 7,
              allDay: true,
              start: DateTime.parse('2025-10-25T22:00:00Z'),
              end: DateTime.parse('2025-10-26T23:00:00Z'),
            ),
          );

          expect(
            dataSource.getEndTime(0),
            tz.TZDateTime(amsterdam, 2025, 10, 26),
          );
        },
      );

      test('isAllDay returns correct value', () {
        expect(dataSource.isAllDay(0), isFalse);

        final allDayHomework = _createHomeworkModel(
          id: 3,
          title: 'All Day',
          start: DateTime.parse('2025-01-15T08:00:00Z'),
          end: DateTime.parse('2025-01-16T08:00:00Z'),
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
          whatsNewVersionSeen: 0,
          showGettingStarted: false,
          gettingStartedDue: false,
          eventsColor: const Color(0xFF4CAF50),
          resourceColor: const Color(0xFF2196F3),
          gradeColor: const Color(0xFFF44336),
          defaultReminderType: 3,
          defaultReminderOffset: 0,
          defaultReminderOffsetType: 0,
          colorByCategory: true,
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
          promptForReview: false,
        );

        final colorByCategoryDataSource = PlannerItemDataSource(
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

    group('typed getters', () {
      test('allHomeworks returns only HomeworkModels', () {
        dataSource.addPlannerItem(_createHomeworkModel(id: 101));
        dataSource.addPlannerItem(_createEventModel(id: 102));
        dataSource.addPlannerItem(_createHomeworkModel(id: 103));

        expect(dataSource.allHomeworks, hasLength(2));
      });

      test('allEvents returns only EventModels', () {
        dataSource.addPlannerItem(_createHomeworkModel(id: 104));
        dataSource.addPlannerItem(_createEventModel(id: 105));
        dataSource.addPlannerItem(_createEventModel(id: 106));

        expect(dataSource.allEvents, hasLength(2));
      });

      test(
        'allCourseScheduleEvents returns only CourseScheduleEventModels',
        () {
          dataSource.addPlannerItem(_createCourseScheduleEventModel(id: 107));
          dataSource.addPlannerItem(_createEventModel(id: 108));
          dataSource.addPlannerItem(_createCourseScheduleEventModel(id: 109));

          expect(dataSource.allCourseScheduleEvents, hasLength(2));
        },
      );

      test(
        'allExternalCalendarEvents returns only ExternalCalendarEventModels',
        () {
          dataSource.addPlannerItem(_createExternalCalendarEventModel(id: 110, title: 'External Event A'));
          dataSource.addPlannerItem(_createEventModel(id: 111));
          dataSource.addPlannerItem(_createExternalCalendarEventModel(id: 112, title: 'External Event B'));

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
    promptForReview: false,
  );
}

DateTime _sfCalendarDateTime(DateTime value, tz.Location calendarZone) {
  final converted = tz.TZDateTime.from(value, calendarZone);
  return DateTime(
    converted.year,
    converted.month,
    converted.day,
    converted.hour,
    converted.minute,
    converted.second,
  );
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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
