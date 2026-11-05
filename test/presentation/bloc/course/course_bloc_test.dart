import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/note_helper.dart';
import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockCourseRepository mockCourseRepository;
  late MockCourseScheduleRepository mockCourseScheduleRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockAttachmentRepository mockAttachmentRepository;
  late MockReminderRepository mockReminderRepository;
  late MockNoteRepository mockNoteRepository;
  late CourseBloc courseBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockCourseRepository = MockCourseRepository();
    mockCourseScheduleRepository = MockCourseScheduleRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockAttachmentRepository = MockAttachmentRepository();
    mockReminderRepository = MockReminderRepository();
    mockNoteRepository = MockNoteRepository();
    courseBloc = CourseBloc(
      courseRepository: mockCourseRepository,
      courseScheduleRepository: mockCourseScheduleRepository,
      categoryRepository: mockCategoryRepository,
      attachmentRepository: mockAttachmentRepository,
      reminderRepository: mockReminderRepository,
      noteRepository: mockNoteRepository,
    );
  });

  tearDown(() {
    courseBloc.close();
  });

  void givenClassNotes(List<NoteModel> notes) {
    when(
      () => mockNoteRepository.getNotes(
        linkedEntityType: 'course',
        courseId: any(named: 'courseId'),
        includeContent: true,
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => notes);
  }

  final request = CourseRequestModel(
    title: 'Biology',
    startDate: '2025-08-25',
    endDate: '2025-12-15',
    room: '',
    credits: '3.0',
    color: '#4CAF50',
    website: '',
    isOnline: false,
    teacherName: '',
    teacherEmail: '',
    courseGroup: 1,
  );

  group('CourseBloc', () {
    test('initial state is CourseInitial with bloc origin', () {
      expect(courseBloc.state, isA<CourseInitial>());
    });

    group('FetchCoursesScreenDataEvent', () {
      blocTest<CourseBloc, CourseState>(
        'a passive fetch emits only the result, with no loading state',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          when(
            () => mockCategoryRepository.getCategories(),
          ).thenAnswer((_) async => MockModels.createCategories());
          when(
            () => mockAttachmentRepository.getAttachments(),
          ).thenAnswer((_) async => MockModels.createAttachments());
          when(
            () => mockReminderRepository.getReminders(sent: false),
          ).thenAnswer((_) async => MockModels.createReminders());
          givenClassNotes([]);
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCoursesScreenDataEvent(origin: EventOrigin.dialog, passive: true),
        ),
        expect: () => [isA<CoursesScreenDataFetched>()],
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesScreenDataFetched] when data fetch succeeds',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroups(),
          ).thenAnswer((_) async => MockModels.createCourseGroups());
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          when(
            () => mockCategoryRepository.getCategories(),
          ).thenAnswer((_) async => MockModels.createCategories());
          when(
            () => mockAttachmentRepository.getAttachments(),
          ).thenAnswer((_) async => MockModels.createAttachments());
          when(
            () => mockReminderRepository.getReminders(sent: false),
          ).thenAnswer((_) async => MockModels.createReminders());
          givenClassNotes([]);
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
          givenClassNotes([]);
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

    group('class notes', () {
      blocTest<CourseBloc, CourseState>(
        'opening a class loads its own note',
        build: () {
          when(
            () => mockCourseRepository.getCourseGroup(1),
          ).thenAnswer((_) async => MockModels.createCourseGroup());
          when(
            () => mockCourseRepository.getCourse(1, 1),
          ).thenAnswer((_) async => MockModels.createCourse());
          givenClassNotes([NoteModel.fromJson(givenNoteJson(id: 4))]);
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseScreenDataEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: 1,
            courseId: 1,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseScreenDataFetched>().having(
            (s) => s.linkedNote?.id,
            'linked note',
            4,
          ),
        ],
        verify: (_) {
          verify(
            () => mockNoteRepository.getNotes(
              linkedEntityType: 'course',
              courseId: 1,
              includeContent: true,
              forceRefresh: false,
            ),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'saving a class saves its edited note too',
        build: () {
          when(
            () => mockCourseRepository.updateCourse(
              1,
              1,
              any(),
              version: any(named: 'version'),
            ),
          ).thenAnswer((_) async => MockModels.createCourse());
          when(
            () => mockNoteRepository.updateNote(
              noteId: 4,
              request: any(named: 'request'),
              version: any(named: 'version'),
            ),
          ).thenAnswer((_) async => NoteModel.fromJson(givenNoteJson(id: 4)));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: 1,
            courseId: 1,
            request: request,
            linkedNote: const LinkedNoteEdit(
              noteId: 4,
              content: {
                'ops': [
                  {'insert': 'Office hours Tuesday\n'},
                ],
              },
            ),
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseUpdated>()
              .having((s) => s.linkedNoteId, 'linked note id', 4)
              .having((s) => s.linkedNoteSave?.isSaved, 'note saved', isTrue),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'a new class with a note creates the note linked to it',
        build: () {
          when(
            () => mockCourseRepository.createCourse(1, any()),
          ).thenAnswer((_) async => MockModels.createCourse(id: 7));
          when(
            () => mockNoteRepository.createNote(request: any(named: 'request')),
          ).thenAnswer((_) async => NoteModel.fromJson(givenNoteJson(id: 9)));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          CreateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: 1,
            request: request,
            noteContent: {
              'ops': [
                {'insert': 'Syllabus highlights\n'},
              ],
            },
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseCreated>()
              .having((s) => s.course.id, 'course', 7)
              .having((s) => s.linkedNoteId, 'linked note id', 9),
        ],
        verify: (_) {
          final sent = verify(
            () => mockNoteRepository.createNote(
              request: captureAny(named: 'request'),
            ),
          ).captured.single as NoteRequestModel;
          expect(sent.courseId, 7);
        },
      );

      blocTest<CourseBloc, CourseState>(
        "when another device already gave the class a note, it's that class's own note that conflicts",
        build: () {
          when(
            () => mockCourseRepository.createCourse(1, any()),
          ).thenAnswer((_) async => MockModels.createCourse(id: 7));
          when(
            () => mockNoteRepository.createNote(request: any(named: 'request')),
          ).thenThrow(ValidationException(message: 'This class already has a linked note.'));
          when(
            () => mockNoteRepository.getNotes(
              linkedEntityType: 'course',
              courseId: 7,
              includeContent: true,
              forceRefresh: true,
            ),
          ).thenAnswer((_) async => [NoteModel.fromJson(givenNoteJson(id: 12))]);
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          CreateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: 1,
            request: request,
            noteContent: {
              'ops': [
                {'insert': 'Mine\n'},
              ],
            },
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseCreated>()
              .having((s) => s.linkedNoteSave?.isConflict, 'conflict', isTrue)
              .having((s) => s.linkedNoteSave?.note?.id, 'existing note', 12),
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

    group('Exceptions', () {
      blocTest<CourseBloc, CourseState>(
        'emits CourseGroupExceptionsUpdated with the saved group',
        build: () {
          when(
            () => mockCourseRepository.updateCourseGroupExceptions(1, any()),
          ).thenAnswer((_) async => MockModels.createCourseGroup(id: 1));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCourseGroupExceptionsEvent(
            origin: EventOrigin.dialog,
            courseGroupId: 1,
            exceptions: [DateTime(2026, 11, 26)],
          ),
        ),
        expect: () => [
          isA<CourseGroupExceptionsUpdated>()
              .having((s) => s.courseGroup.id, 'courseGroup id', 1),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'emits CourseExceptionsUpdated with the saved class',
        build: () {
          when(
            () => mockCourseRepository.updateCourseExceptions(1, 2, any()),
          ).thenAnswer((_) async => MockModels.createCourse(id: 2));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCourseExceptionsEvent(
            origin: EventOrigin.dialog,
            courseGroupId: 1,
            courseId: 2,
            exceptions: [DateTime(2026, 11, 26)],
          ),
        ),
        expect: () => [
          isA<CourseExceptionsUpdated>()
              .having((s) => s.course.id, 'course id', 2),
        ],
      );

      blocTest<CourseBloc, CourseState>(
        'emits CoursesError from the dialog when saving fails',
        build: () {
          when(
            () => mockCourseRepository.updateCourseExceptions(1, 2, any()),
          ).thenThrow(ServerException(message: 'Server error'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCourseExceptionsEvent(
            origin: EventOrigin.dialog,
            courseGroupId: 1,
            courseId: 2,
            exceptions: const [],
          ),
        ),
        expect: () => [
          isA<CoursesError>()
              .having((s) => s.origin, 'origin', EventOrigin.dialog),
        ],
      );
    });

    group('FetchCourseSchedulesEvent', () {
      const courseGroupId = 1;
      const courseId = 2;

      blocTest<CourseBloc, CourseState>(
        'a passive fetch emits only the result, with no loading state',
        build: () {
          when(
            () => mockCourseScheduleRepository.getCourseSchedulesForCourse(
              courseGroupId,
              courseId,
              forceRefresh: any(named: 'forceRefresh'),
            ),
          ).thenAnswer((_) async => [MockModels.createCourseSchedule(id: 10)]);
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseSchedulesEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            passive: true,
          ),
        ),
        expect: () => [isA<CourseSchedulesFetched>()],
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseSchedulesFetched] when fetch succeeds',
        build: () {
          when(
            () => mockCourseScheduleRepository.getCourseSchedulesForCourse(
              courseGroupId,
              courseId,
              forceRefresh: any(named: 'forceRefresh'),
            ),
          ).thenAnswer(
            (_) async => [
              MockModels.createCourseSchedule(id: 10),
              MockModels.createCourseSchedule(id: 11, daysOfWeek: '0010100'),
            ],
          );
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseSchedulesEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseSchedulesFetched>()
              .having((s) => s.schedules.length, 'schedules length', 2),
        ],
        verify: (_) {
          verify(
            () => mockCourseScheduleRepository.getCourseSchedulesForCourse(
              courseGroupId,
              courseId,
              forceRefresh: false,
            ),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when fetch fails',
        build: () {
          when(
            () => mockCourseScheduleRepository.getCourseSchedulesForCourse(
              courseGroupId,
              courseId,
              forceRefresh: any(named: 'forceRefresh'),
            ),
          ).thenThrow(ServerException(message: 'Could not load schedules'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          FetchCourseSchedulesEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: courseGroupId,
            courseId: courseId,
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Could not load schedules',
          ),
        ],
      );
    });

    group('CreateCourseScheduleEvent', () {
      const courseGroupId = 1;
      const courseId = 2;

      blocTest<CourseBloc, CourseState>(
        'emits [CourseScheduleCreated] when create succeeds',
        build: () {
          when(
            () => mockCourseScheduleRepository.createCourseSchedule(
              courseGroupId,
              courseId,
              any(),
            ),
          ).thenAnswer((_) async => MockModels.createCourseSchedule(id: 42));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          CreateCourseScheduleEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            request: MockModels.createCourseScheduleRequest(),
          ),
        ),
        expect: () => [
          isA<CourseScheduleCreated>()
              .having((s) => s.schedule.id, 'schedule id', 42),
        ],
        verify: (_) {
          verify(
            () => mockCourseScheduleRepository.createCourseSchedule(
              courseGroupId,
              courseId,
              any(),
            ),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesError] when create fails',
        build: () {
          when(
            () => mockCourseScheduleRepository.createCourseSchedule(
              courseGroupId,
              courseId,
              any(),
            ),
          ).thenThrow(ServerException(message: 'Could not create schedule'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          CreateCourseScheduleEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            request: MockModels.createCourseScheduleRequest(),
          ),
        ),
        expect: () => [
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Could not create schedule',
          ),
        ],
      );
    });

    group('DeleteCourseScheduleEvent', () {
      const courseGroupId = 1;
      const courseId = 2;
      const scheduleId = 7;

      blocTest<CourseBloc, CourseState>(
        'emits [CourseScheduleDeleted] with the id when deletion succeeds',
        build: () {
          when(
            () => mockCourseScheduleRepository.deleteCourseSchedule(
              courseGroupId,
              courseId,
              scheduleId,
            ),
          ).thenAnswer((_) async {});
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCourseScheduleEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: courseGroupId,
            courseId: courseId,
            scheduleId: scheduleId,
          ),
        ),
        expect: () => [
          isA<CourseScheduleDeleted>().having((s) => s.id, 'id', scheduleId),
        ],
        verify: (_) {
          verify(
            () => mockCourseScheduleRepository.deleteCourseSchedule(
              courseGroupId,
              courseId,
              scheduleId,
            ),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesError] when deletion fails',
        build: () {
          when(
            () => mockCourseScheduleRepository.deleteCourseSchedule(
              courseGroupId,
              courseId,
              scheduleId,
            ),
          ).thenThrow(ServerException(message: 'Could not delete schedule'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCourseScheduleEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: courseGroupId,
            courseId: courseId,
            scheduleId: scheduleId,
          ),
        ),
        expect: () => [
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Could not delete schedule',
          ),
        ],
      );
    });

    group('UpdateCourseScheduleEvent', () {
      const courseGroupId = 1;
      const courseId = 2;
      const scheduleId = 5;

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CourseScheduleUpdated] when update succeeds',
        build: () {
          when(
            () => mockCourseScheduleRepository.updateCourseSchedule(
              courseGroupId,
              courseId,
              scheduleId,
              any(),
            ),
          ).thenAnswer(
            (_) async => MockModels.createCourseSchedule(id: scheduleId),
          );
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCourseScheduleEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            scheduleId: scheduleId,
            request: MockModels.createCourseScheduleRequest(),
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CourseScheduleUpdated>()
              .having((s) => s.schedule.id, 'schedule id', scheduleId),
        ],
        verify: (_) {
          verify(
            () => mockCourseScheduleRepository.updateCourseSchedule(
              courseGroupId,
              courseId,
              scheduleId,
              any(),
            ),
          ).called(1);
        },
      );

      blocTest<CourseBloc, CourseState>(
        'emits [CoursesLoading, CoursesError] when update fails',
        build: () {
          when(
            () => mockCourseScheduleRepository.updateCourseSchedule(
              courseGroupId,
              courseId,
              scheduleId,
              any(),
            ),
          ).thenThrow(ServerException(message: 'Could not update schedule'));
          return courseBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCourseScheduleEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            scheduleId: scheduleId,
            request: MockModels.createCourseScheduleRequest(),
          ),
        ),
        expect: () => [
          isA<CoursesLoading>(),
          isA<CoursesError>().having(
            (e) => e.message,
            'message',
            'Could not update schedule',
          ),
        ],
      );
    });
  });
}
