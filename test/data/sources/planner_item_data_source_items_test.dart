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
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
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
    group('calendar item management', () {
      test('addPlannerItem adds new item', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addPlannerItem(homework);

        expect(dataSource.allPlannerItems, hasLength(1));
        expect(dataSource.appointments, hasLength(1));
        expect(dataSource.allPlannerItems[0].id, 1);
      });

      test('addPlannerItem ignores duplicate', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addPlannerItem(homework);
        dataSource.addPlannerItem(homework);

        expect(dataSource.allPlannerItems, hasLength(1));
      });

      test('updatePlannerItem updates existing item', () {
        final homework = _createHomeworkModel(id: 1, title: 'Original');
        dataSource.addPlannerItem(homework);

        final updated = _createHomeworkModel(id: 1, title: 'Updated');
        dataSource.updatePlannerItem(updated);

        expect(dataSource.allPlannerItems, hasLength(1));
        expect(dataSource.allPlannerItems[0].title, 'Updated');
      });

      test('updatePlannerItem clears completed override', () {
        final homework = _createHomeworkModel(id: 1, completed: false);
        dataSource.addPlannerItem(homework);
        dataSource.setCompletedOverride(1, true);

        final updated = _createHomeworkModel(id: 1, completed: true);
        dataSource.updatePlannerItem(updated);

        expect(dataSource.completedOverrides, isEmpty);
      });

      test('syncLinkedNote removes a deleted note from the item it was linked to', () {
        // GIVEN
        final note = IdOrEntity<NoteModel>(id: 7);
        dataSource.addPlannerItem(_createHomeworkModel(id: 1).copyWith(notes: [note]));
        dataSource.addPlannerItem(_createEventModel(id: 2).copyWith(notes: [IdOrEntity<NoteModel>(id: 8)]));

        // WHEN
        dataSource.syncLinkedNote(7);

        // THEN
        final homework = dataSource.allHomeworks.single;
        expect(homework.notes, isEmpty);
        expect((dataSource.appointments!.firstWhere((item) => item == homework) as HomeworkModel).notes, isEmpty);
        expect(dataSource.allEvents.single.notes.map((linked) => linked.id), [8]);
      });

      test('syncLinkedNote links a created note to its assignment and event', () {
        // GIVEN
        dataSource.addPlannerItem(_createHomeworkModel(id: 1));
        dataSource.addPlannerItem(_createEventModel(id: 2));
        final note = NoteModel(id: 7, title: 'Lab notes', updatedAt: DateTime.utc(2025, 1, 15), homework: [1]);

        // WHEN
        dataSource.syncLinkedNote(7, note: note);

        // THEN
        expect(dataSource.allHomeworks.single.notes.single.id, 7);
        expect(dataSource.allHomeworks.single.notes.single.entity, note);
        expect(dataSource.allEvents.single.notes, isEmpty);
      });

      test('syncLinkedNote moves a relinked note to its new item', () {
        // GIVEN
        dataSource.addPlannerItem(_createHomeworkModel(id: 1).copyWith(notes: [IdOrEntity<NoteModel>(id: 7)]));
        dataSource.addPlannerItem(_createEventModel(id: 2));
        final note = NoteModel(id: 7, title: 'Lab notes', updatedAt: DateTime.utc(2025, 1, 15), events: [2]);

        // WHEN
        dataSource.syncLinkedNote(7, note: note);

        // THEN
        expect(dataSource.allHomeworks.single.notes, isEmpty);
        expect(dataSource.allEvents.single.notes.single.id, 7);
      });

      test('updatePlannerItem hides a shown item that no longer matches the search', () {
        // GIVEN
        dataSource.addPlannerItem(_createHomeworkModel(id: 1, title: 'Quiz 3'));
        dataSource.setSearchQuery('Quiz');

        // WHEN
        dataSource.updatePlannerItem(_createHomeworkModel(id: 1, title: 'Exam 3'));

        // THEN
        expect(dataSource.appointments, isEmpty);
      });

      test('updatePlannerItem hides a toggled item once its completion write settles', () {
        // GIVEN
        dataSource.addPlannerItem(_createHomeworkModel(id: 1, completed: false));
        dataSource.setFilterStatuses({'Incomplete'});
        dataSource.setCompletedOverride(1, true);

        // WHEN
        dataSource.updatePlannerItem(_createHomeworkModel(id: 1, completed: true));

        // THEN
        expect(dataSource.appointments, isEmpty);
      });

      test('updatePlannerItem keeps a toggled item shown while a completion write is pending', () {
        // GIVEN
        dataSource.addPlannerItem(_createHomeworkModel(id: 1, completed: false));
        dataSource.setFilterStatuses({'Incomplete'});
        dataSource.setCompletedOverride(1, false);

        // WHEN
        dataSource.updatePlannerItem(
          _createHomeworkModel(id: 1, completed: true),
          hasPendingCompletionWrite: true,
        );

        // THEN
        expect(dataSource.appointments, hasLength(1));
      });

      test('addPlannerItem adds an assignment that shares its id with a cached event', () {
        // GIVEN
        dataSource.addPlannerItem(_createEventModel(id: 7, title: 'Event 7'));

        // WHEN
        dataSource.addPlannerItem(_createHomeworkModel(id: 7, title: 'Assignment 7'));

        // THEN
        expect(dataSource.allPlannerItems.map((item) => item.title), containsAll(['Event 7', 'Assignment 7']));
        expect(dataSource.appointments, hasLength(2));
      });

      test('updatePlannerItem leaves an event that shares the assignment id in place', () {
        // GIVEN
        dataSource.addPlannerItem(_createEventModel(id: 7, title: 'Event 7'));
        dataSource.addPlannerItem(_createHomeworkModel(id: 7, title: 'Assignment 7'));

        // WHEN
        dataSource.updatePlannerItem(_createHomeworkModel(id: 7, title: 'Assignment 7 saved'));

        // THEN
        expect(dataSource.allPlannerItems.map((item) => item.title), unorderedEquals(['Event 7', 'Assignment 7 saved']));
        expect(dataSource.appointments, hasLength(2));
      });

      test('removePlannerItem leaves an event that shares the assignment id in place', () {
        // GIVEN
        dataSource.addPlannerItem(_createEventModel(id: 7, title: 'Event 7'));
        dataSource.addPlannerItem(_createHomeworkModel(id: 7, title: 'Assignment 7'));

        // WHEN
        dataSource.removePlannerItem(PlannerItemType.homework, 7);

        // THEN
        expect(dataSource.allPlannerItems.map((item) => item.title), ['Event 7']);
        expect(dataSource.appointments, hasLength(1));
      });

      test('removePlannerItem removes item', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addPlannerItem(homework);
        dataSource.removePlannerItem(PlannerItemType.homework, 1);

        expect(dataSource.allPlannerItems, isEmpty);
        expect(dataSource.appointments, isEmpty);
      });

      test('removePlannerItem clears completed override', () {
        final homework = _createHomeworkModel(id: 1);
        dataSource.addPlannerItem(homework);
        dataSource.setCompletedOverride(1, true);
        dataSource.removePlannerItem(PlannerItemType.homework, 1);

        expect(dataSource.completedOverrides, isEmpty);
      });

      test('removePlannerItem handles non-existent item', () {
        dataSource.removePlannerItem(PlannerItemType.homework, 999);
        expect(dataSource.allPlannerItems, isEmpty);
      });
    });

    group('completed overrides', () {
      late HomeworkModel homework;

      setUp(() {
        homework = _createHomeworkModel(id: 1, completed: false);
        dataSource.addPlannerItem(homework);
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

      test('clearCompletedOverride hides an item that no longer matches the status filter', () {
        // GIVEN
        dataSource.setFilterStatuses({'Complete'});
        dataSource.setCompletedOverride(1, true);

        // WHEN
        dataSource.clearCompletedOverride(1);

        // THEN
        expect(dataSource.appointments, isEmpty);
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
        dataSource.addPlannerItem(homework);
      });

      test('getStartTime uses override when present', () {
        dataSource.setTimeOverride(
          homework,
          '2025-01-20T09:00:00Z',
          '2025-01-20T10:00:00Z',
        );

        final adjustment = Sort.getTimedEventStartTimeAdjustmentSeconds(0, 0);
        final expected = tz.TZDateTime.from(
          DateTime.parse('2025-01-20T09:00:00Z'),
          userSettings.timeZone,
        ).subtract(Duration(seconds: adjustment));
        expect(dataSource.getStartTime(0), expected);
      });

      test('getEndTime uses override when present', () {
        dataSource.setTimeOverride(
          homework,
          '2025-01-20T09:00:00Z',
          '2025-01-20T10:00:00Z',
        );

        final adjustment = Sort.getTimedEventStartTimeAdjustmentSeconds(0, 0);
        final expected = tz.TZDateTime.from(
          DateTime.parse('2025-01-20T10:00:00Z'),
          userSettings.timeZone,
        ).subtract(Duration(seconds: adjustment));
        expect(dataSource.getEndTime(0), expected);
      });

      test('setTimeOverride moves only the dragged item when an event shares its id', () {
        // GIVEN
        dataSource.addPlannerItem(_createEventModel(
          id: 1,
          start: DateTime.parse('2025-01-15T12:00:00Z'),
          end: DateTime.parse('2025-01-15T13:00:00Z'),
        ));
        final eventStart = dataSource.getStartTime(
          dataSource.appointments!.indexWhere((a) => a is EventModel),
        );

        // WHEN
        dataSource.setTimeOverride(homework, '2025-01-20T09:00:00Z', '2025-01-20T10:00:00Z');

        // THEN
        expect(
          dataSource.getStartTime(dataSource.appointments!.indexWhere((a) => a is EventModel)),
          eventStart,
        );
      });

      test('updatePlannerItem clears time override', () {
        dataSource.setTimeOverride(
          homework,
          '2025-01-20T09:00:00Z',
          '2025-01-20T10:00:00Z',
        );

        final updated = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-16T14:00:00Z'),
          end: DateTime.parse('2025-01-16T15:00:00Z'),
        );
        dataSource.updatePlannerItem(updated);

        final adjustment = Sort.getTimedEventStartTimeAdjustmentSeconds(0, 0);
        final expected = tz.TZDateTime.from(
          DateTime.parse('2025-01-16T14:00:00Z'),
          userSettings.timeZone,
        ).subtract(Duration(seconds: adjustment));
        final index = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 1,
        );
        expect(dataSource.getStartTime(index), expected);
      });
    });

    group('getStartTime sort encoding', () {
      test('homework sorts before courseSchedule at the same start time', () {
        final schedule = _createCourseScheduleEventModel(id: 1);
        final homework = _createHomeworkModel(
          id: 2,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addPlannerItem(schedule);
        dataSource.addPlannerItem(homework);

        final hwIndex = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 2,
        );
        final schedIndex = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 1,
        );

        expect(
          dataSource.getStartTime(hwIndex).isBefore(
            dataSource.getStartTime(schedIndex),
          ),
          isTrue,
          reason: 'homework (priority 0) must sort before courseSchedule (priority 1)',
        );
      });

      test('homework sorts before event at the same start time', () {
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
        dataSource.addPlannerItem(event);
        dataSource.addPlannerItem(homework);

        final hwIndex = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 2,
        );
        final eventIndex = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 1,
        );

        expect(
          dataSource.getStartTime(hwIndex).isBefore(
            dataSource.getStartTime(eventIndex),
          ),
          isTrue,
          reason: 'homework (priority 0) must sort before event (priority 2)',
        );
      });

      test('all four types produce distinct ordered start times at the same time', () {
        final external = _createExternalCalendarEventModel(id: 1);
        final event = _createEventModel(
          id: 2,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        final schedule = _createCourseScheduleEventModel(id: 3);
        final homework = _createHomeworkModel(
          id: 4,
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );

        dataSource.addPlannerItem(external);
        dataSource.addPlannerItem(event);
        dataSource.addPlannerItem(schedule);
        dataSource.addPlannerItem(homework);

        DateTime startFor(int id) {
          final index = dataSource.appointments!.indexWhere(
            (a) => (a as PlannerItemBaseModel).id == id,
          );
          return dataSource.getStartTime(index);
        }

        final hwStart = startFor(4);
        final schedStart = startFor(3);
        final eventStart = startFor(2);
        final extStart = startFor(1);

        expect(hwStart.isBefore(schedStart), isTrue);
        expect(schedStart.isBefore(eventStart), isTrue);
        expect(eventStart.isBefore(extStart), isTrue);
      });

      test('single all-day homework has no offset (priority 0, position 0)', () {
        final allDayHomework = _createHomeworkModel(
          id: 1,
          start: DateTime.parse('2025-01-15T08:00:00Z'),
          end: DateTime.parse('2025-01-16T08:00:00Z'),
          allDay: true,
        );
        dataSource.addPlannerItem(allDayHomework);

        final startTime = dataSource.getStartTime(0);
        final expected = tz.TZDateTime(userSettings.timeZone, 2025, 1, 15);
        expect(startTime, expected);
      });

      test('two same-type all-day items get distinct start times preserving sort order', () {
        final hw1 = _createHomeworkModel(
          id: 1,
          title: 'Quiz 4',
          start: DateTime.parse('2025-01-15T08:00:00Z'),
          end: DateTime.parse('2025-01-16T08:00:00Z'),
          allDay: true,
        );
        final hw2 = _createHomeworkModel(
          id: 2,
          title: 'Quiz 5',
          start: DateTime.parse('2025-01-15T08:00:00Z'),
          end: DateTime.parse('2025-01-16T08:00:00Z'),
          allDay: true,
        );
        dataSource.addPlannerItem(hw2);
        dataSource.addPlannerItem(hw1);

        final hw1Index = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 1,
        );
        final hw2Index = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 2,
        );

        expect(
          dataSource.getStartTime(hw1Index).isBefore(
            dataSource.getStartTime(hw2Index),
          ),
          isTrue,
          reason: 'Quiz 4 must appear before Quiz 5',
        );
      });

      test('two same-type timed items at same time get distinct start times', () {
        final hw1 = _createHomeworkModel(
          id: 1,
          title: 'Alpha',
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        final hw2 = _createHomeworkModel(
          id: 2,
          title: 'Beta',
          start: DateTime.parse('2025-01-15T10:00:00Z'),
          end: DateTime.parse('2025-01-15T11:00:00Z'),
        );
        dataSource.addPlannerItem(hw1);
        dataSource.addPlannerItem(hw2);

        final hw1Index = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 1,
        );
        final hw2Index = dataSource.appointments!.indexWhere(
          (a) => (a as PlannerItemBaseModel).id == 2,
        );

        final hw1Start = dataSource.getStartTime(hw1Index);
        final hw2Start = dataSource.getStartTime(hw2Index);

        expect(hw1Start.isBefore(hw2Start), isTrue);
        expect(hw2Start.difference(hw1Start).inMinutes, 0);
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
