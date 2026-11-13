import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/note_helper.dart';
import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockEventRepository mockEventRepository;
  late MockHomeworkRepository mockHomeworkRepository;
  late MockCourseRepository mockCourseRepository;
  late MockCourseScheduleRepository mockCourseScheduleRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockResourceRepository mockResourceRepository;
  late MockNoteRepository mockNoteRepository;
  late PlannerItemBloc plannerItemBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockHomeworkRepository = MockHomeworkRepository();
    mockCourseRepository = MockCourseRepository();
    mockCourseScheduleRepository = MockCourseScheduleRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockResourceRepository = MockResourceRepository();
    mockNoteRepository = MockNoteRepository();
    plannerItemBloc = PlannerItemBloc(
      eventRepository: mockEventRepository,
      homeworkRepository: mockHomeworkRepository,
      courseRepository: mockCourseRepository,
      courseScheduleRepository: mockCourseScheduleRepository,
      categoryRepository: mockCategoryRepository,
      resourceRepository: mockResourceRepository,
      noteRepository: mockNoteRepository,
    );
  });

  tearDown(() {
    plannerItemBloc.close();
  });

  group('PlannerItemBloc', () {
    test('initial state is PlannerItemInitial with bloc origin', () {
      expect(plannerItemBloc.state, isA<PlannerItemInitial>());
    });

    group('FetchPlannerItemScreenDataEvent', () {
      blocTest<PlannerItemBloc, PlannerItemState>(
        'emits [PlannerItemsLoading, PlannerItemScreenDataFetched] for event',
        build: () {
          when(
            () => mockEventRepository.getEvent(id: 1),
          ).thenAnswer((_) async => MockModels.createEvent(id: 1));
          when(
            () => mockNoteRepository.getNotes(eventId: 1, includeContent: true),
          ).thenAnswer((_) async => []);
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          FetchPlannerItemScreenDataEvent(
            origin: EventOrigin.screen,
            eventId: 1,
          ),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<PlannerItemScreenDataFetched>()
              .having((s) => s.plannerItem?.id, 'event id', 1)
              .having((s) => s.courseGroups, 'courseGroups', isEmpty)
              .having((s) => s.courses, 'courses', isEmpty)
              .having((s) => s.categories, 'categories', isEmpty),
        ],
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'emits [PlannerItemsLoading, PlannerItemScreenDataFetched] for homework with related data',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourses());
          when(
            () => mockCourseScheduleRepository.getCourseSchedules(
              shownOnCalendar: true,
            ),
          ).thenAnswer((_) async => [MockModels.createCourseSchedule()]);
          when(
            () => mockCategoryRepository.getCategories(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCategories());
          when(
            () => mockHomeworkRepository.getHomework(id: 1),
          ).thenAnswer((_) async => MockModels.createHomework(id: 1));
          when(
            () => mockResourceRepository.getResources(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createResources());
          when(
            () => mockNoteRepository.getNotes(homeworkId: 1, includeContent: true),
          ).thenAnswer((_) async => []);
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          FetchPlannerItemScreenDataEvent(
            origin: EventOrigin.screen,
            homeworkId: 1,
          ),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<PlannerItemScreenDataFetched>()
              .having((s) => s.plannerItem?.id, 'homework id', 1)
              .having((s) => s.courseGroups.length, 'courseGroups length', 2)
              .having((s) => s.courses.length, 'courses length', 3)
              .having((s) => s.categories.length, 'categories length', 3),
        ],
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'emits [PlannerItemsLoading, PlannerItemScreenDataFetched] for new homework (no id)',
        build: () {
          when(
                () => mockCourseRepository.getCourseGroups(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCourses());
          when(
            () => mockCourseScheduleRepository.getCourseSchedules(
              shownOnCalendar: true,
            ),
          ).thenAnswer((_) async => [MockModels.createCourseSchedule()]);
          when(
            () => mockCategoryRepository.getCategories(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createCategories());
          when(
            () => mockResourceRepository.getResources(shownOnCalendar: true),
          ).thenAnswer((_) async => MockModels.createResources());
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          FetchPlannerItemScreenDataEvent(origin: EventOrigin.screen),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<PlannerItemScreenDataFetched>()
              .having((s) => s.plannerItem, 'calendar item', isNull)
              .having((s) => s.courseGroups.length, 'courseGroups length', 2)
              .having((s) => s.courses.length, 'courses length', 3),
        ],
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'emits [PlannerItemsLoading, PlannerItemsError] when fetch fails',
        build: () {
          when(
            () => mockEventRepository.getEvent(id: 999),
          ).thenThrow(NotFoundException(message: 'Event not found'));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          FetchPlannerItemScreenDataEvent(
            origin: EventOrigin.screen,
            eventId: 999,
          ),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<PlannerItemsError>().having(
            (e) => e.message,
            'message',
            'Event not found',
          ),
        ],
      );
    });

    group('Event CRUD operations', () {
      group('CreateEventEvent', () {
        final request = EventRequestModel(
          title: 'New Event',
          allDay: false,
          showEndTime: true,
          start: '2025-01-15T10:00:00Z',
          end: '2025-01-15T11:00:00Z',
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, EventCreated] when creation succeeds',
          build: () {
            when(
              () => mockEventRepository.createEvent(request: any(named: 'request')),
            ).thenAnswer(
              (_) async => MockModels.createEvent(id: 10, title: 'New Event'),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            CreateEventEvent(origin: EventOrigin.dialog, request: request),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<EventCreated>()
                .having((s) => s.event.id, 'event id', 10)
                .having((s) => s.advanceNavOnSuccess, 'advanceNavOnSuccess', isTrue),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when creation fails',
          build: () {
            when(
              () => mockEventRepository.createEvent(request: any(named: 'request')),
            ).thenThrow(ValidationException(message: 'Invalid event data'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            CreateEventEvent(origin: EventOrigin.dialog, request: request),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemsError>().having(
              (e) => e.message,
              'message',
              'Invalid event data',
            ),
          ],
        );
      });

      group('UpdateEventEvent', () {
        const eventId = 5;
        final request = EventRequestModel(
          title: 'Updated Event',
          allDay: false,
          showEndTime: true,
          start: '2025-01-15T10:00:00Z',
          end: '2025-01-15T12:00:00Z',
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, EventUpdated] when update succeeds',
          build: () {
            when(
              () => mockEventRepository.updateEvent(
                eventId: eventId,
                request: any(named: 'request'),
              ),
            ).thenAnswer(
              (_) async => MockModels.createEvent(
                id: eventId,
                title: 'Updated Event',
              ),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateEventEvent(
              origin: EventOrigin.dialog,
              id: eventId,
              request: request,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<EventUpdated>()
                .having((s) => s.event.id, 'event id', eventId)
                .having((s) => s.event.title, 'title', 'Updated Event'),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when update fails',
          build: () {
            when(
              () => mockEventRepository.updateEvent(
                eventId: eventId,
                request: any(named: 'request'),
              ),
            ).thenThrow(NotFoundException(message: 'Event not found'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateEventEvent(
              origin: EventOrigin.dialog,
              id: eventId,
              request: request,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemsError>().having(
              (e) => e.message,
              'message',
              'Event not found',
            ),
          ],
        );
      });

      group('DeleteEventEvent', () {
        const eventId = 5;

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, EventDeleted] when deletion succeeds',
          build: () {
            when(
              () => mockEventRepository.deleteEvent(eventId: eventId),
            ).thenAnswer((_) async {});
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            DeleteEventEvent(origin: EventOrigin.dialog, id: eventId),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<EventDeleted>().having((s) => s.id, 'id', eventId),
          ],
        );

        final eventDeleteInFlight = Completer<void>();

        blocTest<PlannerItemBloc, PlannerItemState>(
          'sends one request when the same event is deleted twice while the first is in flight',
          build: () {
            when(
              () => mockEventRepository.deleteEvent(eventId: eventId),
            ).thenAnswer((_) => eventDeleteInFlight.future);
            return plannerItemBloc;
          },
          act: (bloc) async {
            bloc.add(DeleteEventEvent(origin: EventOrigin.dialog, id: eventId));
            bloc.add(DeleteEventEvent(origin: EventOrigin.dialog, id: eventId));
            await Future<void>.delayed(Duration.zero);
            eventDeleteInFlight.complete();
          },
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<EventDeleted>().having((s) => s.id, 'id', eventId),
          ],
          verify: (_) {
            verify(() => mockEventRepository.deleteEvent(eventId: eventId))
                .called(1);
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when deletion fails',
          build: () {
            when(
              () => mockEventRepository.deleteEvent(eventId: eventId),
            ).thenThrow(ServerException(message: 'Cannot delete event'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            DeleteEventEvent(origin: EventOrigin.dialog, id: eventId),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemsError>().having(
              (e) => e.message,
              'message',
              'Cannot delete event',
            ),
          ],
        );
      });
    });

    group('Homework CRUD operations', () {
      group('CreateHomeworkEvent', () {
        const courseGroupId = 1;
        const courseId = 2;
        final request = HomeworkRequestModel(
          course: courseId,
          title: 'New Homework',
          allDay: false,
          showEndTime: true,
          start: '2025-01-15T10:00:00Z',
          end: '2025-01-15T11:00:00Z',
          category: 1,
          completed: false,
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, HomeworkCreated] when creation succeeds',
          build: () {
            when(
              () => mockHomeworkRepository.createHomework(
                groupId: courseGroupId,
                courseId: courseId,
                request: any(named: 'request'),
              ),
            ).thenAnswer(
              (_) async => MockModels.createHomework(
                id: 10,
                title: 'New Homework',
              ),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            CreateHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              request: request,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkCreated>()
                .having((s) => s.homework.id, 'homework id', 10)
                .having((s) => s.isEvent, 'isEvent', isFalse),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when creation fails',
          build: () {
            when(
              () => mockHomeworkRepository.createHomework(
                groupId: courseGroupId,
                courseId: courseId,
                request: any(named: 'request'),
              ),
            ).thenThrow(ValidationException(message: 'Invalid homework data'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            CreateHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              request: request,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemsError>().having(
              (e) => e.message,
              'message',
              'Invalid homework data',
            ),
          ],
        );
      });

      group('UpdateHomeworkEvent', () {
        const courseGroupId = 1;
        const courseId = 2;
        const homeworkId = 5;
        final request = HomeworkRequestModel(
          course: courseId,
          title: 'Updated Homework',
          allDay: false,
          showEndTime: true,
          start: '2025-01-15T10:00:00Z',
          end: '2025-01-15T12:00:00Z',
          category: 1,
          completed: true,
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, HomeworkUpdated] when update succeeds',
          build: () {
            when(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
                request: any(named: 'request'),
              ),
            ).thenAnswer(
              (_) async => MockModels.createHomework(
                id: homeworkId,
                title: 'Updated Homework',
                completed: true,
              ),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
              request: request,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkUpdated>()
                .having((s) => s.homework.id, 'homework id', homeworkId)
                .having((s) => s.homework.completed, 'completed', isTrue),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits PlannerItemConflict when the homework changed elsewhere',
          build: () {
            when(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
                request: any(named: 'request'),
                version: 'v1',
              ),
            ).thenAnswer((_) async => throw ConflictException(latest: {}));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
              request: request,
              version: 'v1',
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemConflict>().having(
              (s) => s.linkedNoteSave?.isConflict ?? false,
              'linked note conflict',
              isFalse,
            ),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'reports a linked note conflict without saving a copy',
          build: () {
            when(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
                request: any(named: 'request'),
                version: any(named: 'version'),
              ),
            ).thenAnswer(
              (_) async => MockModels.createHomework(id: homeworkId),
            );
            when(
              () => mockNoteRepository.updateNote(
                noteId: 3,
                request: any(named: 'request'),
                version: 'note-v1',
              ),
            ).thenAnswer(
              (_) async => throw ConflictException(
                latest: {
                  'id': 3,
                  'title': 'Updated Homework',
                  'updated_at': '2026-10-07T11:00:00Z',
                },
              ),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
              request: request,
              linkedNote: const LinkedNoteEdit(
                noteId: 3,
                version: 'note-v1',
                content: {'ops': []},
              ),
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkUpdated>()
                .having(
                  (s) => s.linkedNoteSave?.isConflict,
                  'linked note conflict',
                  isTrue,
                )
                .having(
                  (s) => s.linkedNoteSave?.note?.version,
                  'latest note version',
                  '2026-10-07T11:00:00Z',
                )
                .having((s) => s.linkedNoteId, 'linkedNoteId', 3),
          ],
          verify: (_) {
            verifyNever(
              () => mockNoteRepository.createNote(
                request: any(named: 'request'),
              ),
            );
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'does not save an untouched linked note',
          build: () {
            when(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
                request: any(named: 'request'),
                version: any(named: 'version'),
              ),
            ).thenAnswer(
              (_) async => MockModels.createHomework(id: homeworkId),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
              request: request,
              linkedNote: const LinkedNoteEdit(
                noteId: 3,
                edited: false,
                content: {'ops': []},
              ),
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkUpdated>()
                .having((s) => s.linkedNoteId, 'linkedNoteId', 3),
          ],
          verify: (_) {
            verifyNever(
              () => mockNoteRepository.updateNote(
                noteId: any(named: 'noteId'),
                request: any(named: 'request'),
                version: any(named: 'version'),
              ),
            );
            verifyNever(
              () => mockNoteRepository.createNote(
                request: any(named: 'request'),
              ),
            );
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when update fails',
          build: () {
            when(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
                request: any(named: 'request'),
              ),
            ).thenThrow(NotFoundException(message: 'Homework not found'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
              request: request,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemsError>().having(
              (e) => e.message,
              'message',
              'Homework not found',
            ),
          ],
        );
      });

      group('DeleteHomeworkEvent', () {
        const courseGroupId = 1;
        const courseId = 2;
        const homeworkId = 5;

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, HomeworkDeleted] when deletion succeeds',
          build: () {
            when(
              () => mockHomeworkRepository.deleteHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
              ),
            ).thenAnswer((_) async {});
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            DeleteHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkDeleted>().having((s) => s.id, 'id', homeworkId),
          ],
        );

        final homeworkDeleteInFlight = Completer<void>();

        blocTest<PlannerItemBloc, PlannerItemState>(
          'sends one request when the same homework is deleted twice while the first is in flight',
          build: () {
            when(
              () => mockHomeworkRepository.deleteHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
              ),
            ).thenAnswer((_) => homeworkDeleteInFlight.future);
            return plannerItemBloc;
          },
          act: (bloc) async {
            final delete = DeleteHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
            );
            bloc.add(delete);
            bloc.add(delete);
            await Future<void>.delayed(Duration.zero);
            homeworkDeleteInFlight.complete();
          },
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkDeleted>().having((s) => s.id, 'id', homeworkId),
          ],
          verify: (_) {
            verify(
              () => mockHomeworkRepository.deleteHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
              ),
            ).called(1);
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when deletion fails',
          build: () {
            when(
              () => mockHomeworkRepository.deleteHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: homeworkId,
              ),
            ).thenThrow(ServerException(message: 'Cannot delete homework'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            DeleteHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: homeworkId,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<PlannerItemsError>().having(
              (e) => e.message,
              'message',
              'Cannot delete homework',
            ),
          ],
        );
      });
    });

    group('Recurrence', () {
      const seriesId = 28;
      const detachedId = 33;
      final occurrenceStart = DateTime.utc(2026, 11, 26, 11);
      final request = EventRequestModel(start: '2026-11-27T11:00:00Z', end: '2026-11-27T12:00:00Z');
      const noteContent = {
        'ops': [
          {'insert': 'Bring the lab manual\n'},
        ],
      };

      void givenDetachSucceeds() {
        when(
          () => mockEventRepository.updateEvent(
            eventId: seriesId,
            request: any(named: 'request'),
            occurrenceStart: occurrenceStart,
            onlyThisOccurrence: true,
          ),
        ).thenAnswer((_) async => MockModels.createEvent(id: detachedId, title: 'Moved'));
        when(
          () => mockNoteRepository.createNote(request: any(named: 'request')),
        ).thenAnswer((_) async => NoteModel.fromJson(givenNoteJson(id: 70)));
      }

      blocTest<PlannerItemBloc, PlannerItemState>(
        'detaching an occurrence emits the standalone event with the refetched series, saving the note to the series',
        build: () {
          givenDetachSucceeds();
          when(
            () => mockEventRepository.getEvent(id: seriesId, forceRefresh: true),
          ).thenAnswer((_) async => MockModels.createEvent(id: seriesId, recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH'));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          UpdateEventEvent(
            origin: EventOrigin.dialog,
            id: seriesId,
            request: request,
            occurrenceStart: occurrenceStart,
            onlyThisOccurrence: true,
            linkedNote: const LinkedNoteEdit(content: noteContent),
          ),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventUpdated>()
              .having((s) => s.event.id, 'event id', detachedId)
              .having((s) => s.entityId, 'entityId', detachedId)
              .having((s) => s.seriesId, 'seriesId', seriesId)
              .having((s) => s.series?.id, 'series id', seriesId)
              .having((s) => s.series?.recurrenceRule, 'series rule', 'FREQ=WEEKLY;BYDAY=TH')
              .having((s) => s.linkedNoteId, 'linkedNoteId', 70),
        ],
        verify: (_) {
          final noteRequest = verify(
            () => mockNoteRepository.createNote(request: captureAny(named: 'request')),
          ).captured.single as NoteRequestModel;
          expect(noteRequest.eventId, seriesId, reason: 'the note belongs to the series while it has occurrences');
          verifyNever(
            () => mockEventRepository.updateEvent(
              eventId: seriesId,
              request: any(named: 'request'),
              version: any(named: 'version'),
            ),
          );
        },
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'detaching the last occurrence emits no series and saves the note to the standalone event',
        build: () {
          givenDetachSucceeds();
          when(
            () => mockEventRepository.getEvent(id: seriesId, forceRefresh: true),
          ).thenAnswer((_) async => throw NotFoundException(message: 'Not found'));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          UpdateEventEvent(
            origin: EventOrigin.dialog,
            id: seriesId,
            request: request,
            occurrenceStart: occurrenceStart,
            onlyThisOccurrence: true,
            linkedNote: const LinkedNoteEdit(content: noteContent),
          ),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventUpdated>()
              .having((s) => s.event.id, 'event id', detachedId)
              .having((s) => s.seriesId, 'seriesId', seriesId)
              .having((s) => s.series, 'series', isNull),
        ],
        verify: (_) {
          final noteRequest = verify(
            () => mockNoteRepository.createNote(request: captureAny(named: 'request')),
          ).captured.single as NoteRequestModel;
          expect(noteRequest.eventId, detachedId,
              reason: 'the series was deleted and handed its note to the standalone event');
        },
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'moving the whole series from an occurrence passes the occurrence without detaching',
        build: () {
          when(
            () => mockEventRepository.updateEvent(
              eventId: seriesId,
              request: any(named: 'request'),
              occurrenceStart: occurrenceStart,
            ),
          ).thenAnswer((_) async => MockModels.createEvent(id: seriesId, recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR'));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          UpdateEventEvent(
            origin: EventOrigin.dialog,
            id: seriesId,
            request: request,
            occurrenceStart: occurrenceStart,
          ),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventUpdated>()
              .having((s) => s.event.id, 'event id', seriesId)
              .having((s) => s.event.recurrenceRule, 'rule', 'FREQ=WEEKLY;BYDAY=FR')
              .having((s) => s.seriesId, 'seriesId', isNull),
        ],
        verify: (_) {
          verify(
            () => mockEventRepository.updateEvent(
              eventId: seriesId,
              request: any(named: 'request'),
              occurrenceStart: occurrenceStart,
            ),
          ).called(1);
          verifyNever(() => mockEventRepository.getEvent(id: seriesId, forceRefresh: true));
        },
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'deleting an occurrence emits the refetched series',
        build: () {
          when(
            () => mockEventRepository.deleteEvent(eventId: seriesId, occurrenceStart: occurrenceStart),
          ).thenAnswer((_) async {});
          when(
            () => mockEventRepository.getEvent(id: seriesId, forceRefresh: true),
          ).thenAnswer((_) async => MockModels.createEvent(id: seriesId, recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH'));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          DeleteEventEvent(origin: EventOrigin.dialog, id: seriesId, occurrenceStart: occurrenceStart),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventDeleted>()
              .having((s) => s.id, 'id', seriesId)
              .having((s) => s.series?.id, 'series id', seriesId),
        ],
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'deleting the last occurrence emits no series, as the series was deleted with it',
        build: () {
          when(
            () => mockEventRepository.deleteEvent(eventId: seriesId, occurrenceStart: occurrenceStart),
          ).thenAnswer((_) async {});
          when(
            () => mockEventRepository.getEvent(id: seriesId, forceRefresh: true),
          ).thenAnswer((_) async => throw NotFoundException(message: 'Not found'));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          DeleteEventEvent(origin: EventOrigin.dialog, id: seriesId, occurrenceStart: occurrenceStart),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventDeleted>().having((s) => s.id, 'id', seriesId).having((s) => s.series, 'series', isNull),
        ],
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'deleting a whole event never refetches it',
        build: () {
          when(() => mockEventRepository.deleteEvent(eventId: seriesId)).thenAnswer((_) async {});
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(DeleteEventEvent(origin: EventOrigin.dialog, id: seriesId)),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventDeleted>().having((s) => s.series, 'series', isNull),
        ],
        verify: (_) {
          verifyNever(() => mockEventRepository.getEvent(id: any(named: 'id'), forceRefresh: true));
        },
      );

      blocTest<PlannerItemBloc, PlannerItemState>(
        'cloning from an occurrence passes its start',
        build: () {
          when(
            () => mockEventRepository.cloneEvent(eventId: seriesId, occurrenceStart: occurrenceStart),
          ).thenAnswer((_) async => MockModels.createEvent(id: 40, start: occurrenceStart));
          return plannerItemBloc;
        },
        act: (bloc) => bloc.add(
          CloneEventEvent(origin: EventOrigin.dialog, eventId: seriesId, occurrenceStart: occurrenceStart),
        ),
        expect: () => [
          isA<PlannerItemsLoading>(),
          isA<EventCreated>()
              .having((s) => s.event.id, 'event id', 40)
              .having((s) => s.event.start, 'start', occurrenceStart)
              .having((s) => s.isClone, 'isClone', isTrue),
        ],
      );

      group('repeating assignments', () {
        const courseGroupId = 1;
        const courseId = 2;
        final occurrence = MockModels.createHomework(
          id: seriesId,
          start: occurrenceStart,
          end: occurrenceStart,
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH',
        );

        void givenDetachSucceeds() {
          when(
            () => mockHomeworkRepository.updateHomework(
              groupId: courseGroupId,
              courseId: courseId,
              homeworkId: seriesId,
              request: any(named: 'request'),
              occurrenceStart: occurrenceStart,
              onlyThisOccurrence: true,
            ),
          ).thenAnswer((_) async => MockModels.createHomework(id: detachedId, completed: true));
        }

        UpdateHomeworkEvent completeOccurrence() => UpdateHomeworkEvent(
              origin: EventOrigin.screen,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: seriesId,
              request: HomeworkRequestModel(completed: true),
              previousHomework: occurrence,
              occurrenceStart: occurrenceStart,
              onlyThisOccurrence: true,
            );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'completing an occurrence emits the standalone assignment with the refetched series',
          build: () {
            givenDetachSucceeds();
            when(
              () => mockHomeworkRepository.getHomework(id: seriesId, forceRefresh: true),
            ).thenAnswer(
              (_) async => MockModels.createHomework(
                id: seriesId,
                recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH',
                exceptionDates: [occurrenceStart],
              ),
            );
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(completeOccurrence()),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkUpdated>()
                .having((s) => s.homework.id, 'homework id', detachedId)
                .having((s) => s.homework.completed, 'completed', isTrue)
                .having((s) => s.entityId, 'entityId', detachedId)
                .having((s) => s.seriesId, 'seriesId', seriesId)
                .having((s) => s.series?.exceptionDates, 'series exception dates', [occurrenceStart])
                .having((s) => s.previousHomework, 'previousHomework', same(occurrence)),
          ],
          verify: (_) {
            final sent = verify(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: seriesId,
                request: captureAny(named: 'request'),
                occurrenceStart: occurrenceStart,
                onlyThisOccurrence: true,
              ),
            ).captured.single as HomeworkRequestModel;
            expect(sent.toJson(), {'completed': true});
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'completing the last occurrence emits no series',
          build: () {
            givenDetachSucceeds();
            when(
              () => mockHomeworkRepository.getHomework(id: seriesId, forceRefresh: true),
            ).thenAnswer((_) async => throw NotFoundException(message: 'Not found'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(completeOccurrence()),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkUpdated>()
                .having((s) => s.homework.id, 'homework id', detachedId)
                .having((s) => s.seriesId, 'seriesId', seriesId)
                .having((s) => s.series, 'series', isNull),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'moving the whole series from an occurrence passes the occurrence without detaching',
          build: () {
            when(
              () => mockHomeworkRepository.updateHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: seriesId,
                request: any(named: 'request'),
                occurrenceStart: occurrenceStart,
              ),
            ).thenAnswer((_) async => MockModels.createHomework(id: seriesId, recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            UpdateHomeworkEvent(
              origin: EventOrigin.screen,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: seriesId,
              request: HomeworkRequestModel(start: '2026-11-27T11:00:00Z', end: '2026-11-27T11:00:00Z'),
              occurrenceStart: occurrenceStart,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkUpdated>()
                .having((s) => s.homework.recurrenceRule, 'rule', 'FREQ=WEEKLY;BYDAY=FR')
                .having((s) => s.seriesId, 'seriesId', isNull),
          ],
          verify: (_) {
            verifyNever(() => mockHomeworkRepository.getHomework(id: seriesId, forceRefresh: true));
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'deleting an occurrence emits the refetched series',
          build: () {
            when(
              () => mockHomeworkRepository.deleteHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: seriesId,
                occurrenceStart: occurrenceStart,
              ),
            ).thenAnswer((_) async {});
            when(
              () => mockHomeworkRepository.getHomework(id: seriesId, forceRefresh: true),
            ).thenAnswer((_) async => MockModels.createHomework(id: seriesId, recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            DeleteHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: seriesId,
              occurrenceStart: occurrenceStart,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkDeleted>()
                .having((s) => s.id, 'id', seriesId)
                .having((s) => s.series?.id, 'series id', seriesId),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'deleting a whole series never refetches it',
          build: () {
            when(
              () => mockHomeworkRepository.deleteHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: seriesId,
              ),
            ).thenAnswer((_) async {});
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            DeleteHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: seriesId,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkDeleted>().having((s) => s.series, 'series', isNull),
          ],
          verify: (_) {
            verifyNever(() => mockHomeworkRepository.getHomework(id: any(named: 'id'), forceRefresh: true));
          },
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'cloning from an occurrence passes its start',
          build: () {
            when(
              () => mockHomeworkRepository.cloneHomework(
                groupId: courseGroupId,
                courseId: courseId,
                homeworkId: seriesId,
                occurrenceStart: occurrenceStart,
              ),
            ).thenAnswer((_) async => MockModels.createHomework(id: 40, start: occurrenceStart));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            CloneHomeworkEvent(
              origin: EventOrigin.dialog,
              courseGroupId: courseGroupId,
              courseId: courseId,
              homeworkId: seriesId,
              occurrenceStart: occurrenceStart,
            ),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkCreated>()
                .having((s) => s.homework.id, 'homework id', 40)
                .having((s) => s.homework.start, 'start', occurrenceStart)
                .having((s) => s.isClone, 'isClone', isTrue),
          ],
        );
      });
    });
  });
}
