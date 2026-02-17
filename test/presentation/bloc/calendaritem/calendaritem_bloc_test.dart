// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/presentation/bloc/planneritem/planneritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/planneritem/planneritem_event.dart';
import 'package:heliumapp/presentation/bloc/planneritem/planneritem_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:mocktail/mocktail.dart';

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
    plannerItemBloc = PlannerItemBloc(
      eventRepository: mockEventRepository,
      homeworkRepository: mockHomeworkRepository,
      courseRepository: mockCourseRepository,
      courseScheduleRepository: mockCourseScheduleRepository,
      categoryRepository: mockCategoryRepository,
      resourceRepository: mockResourceRepository,
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
      group('FetchEventEvent', () {
        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, EventFetched] when fetch succeeds',
          build: () {
            when(
              () => mockEventRepository.getEvent(id: 1),
            ).thenAnswer((_) async => MockModels.createEvent(id: 1));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            FetchEventEvent(origin: EventOrigin.screen, eventId: 1),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<EventFetched>()
                .having((s) => s.event.id, 'event id', 1)
                .having((s) => s.isEvent, 'isEvent', isTrue),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when event not found',
          build: () {
            when(
              () => mockEventRepository.getEvent(id: 999),
            ).thenThrow(NotFoundException(message: 'Event not found'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            FetchEventEvent(origin: EventOrigin.screen, eventId: 999),
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
      group('FetchHomeworkEvent', () {
        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, HomeworkFetched] when fetch succeeds',
          build: () {
            when(
              () => mockHomeworkRepository.getHomework(id: 1),
            ).thenAnswer((_) async => MockModels.createHomework(id: 1));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            FetchHomeworkEvent(origin: EventOrigin.screen, id: 1),
          ),
          expect: () => [
            isA<PlannerItemsLoading>(),
            isA<HomeworkFetched>()
                .having((s) => s.homework.id, 'homework id', 1)
                .having((s) => s.isEvent, 'isEvent', isFalse),
          ],
        );

        blocTest<PlannerItemBloc, PlannerItemState>(
          'emits [PlannerItemsLoading, PlannerItemsError] when homework not found',
          build: () {
            when(
              () => mockHomeworkRepository.getHomework(id: 999),
            ).thenThrow(NotFoundException(message: 'Homework not found'));
            return plannerItemBloc;
          },
          act: (bloc) => bloc.add(
            FetchHomeworkEvent(origin: EventOrigin.screen, id: 999),
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
  });
}
