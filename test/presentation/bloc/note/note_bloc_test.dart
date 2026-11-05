import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/note_helper.dart';
import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  const version = '2026-10-07T12:00:00.123456Z';
  late MockNoteRepository mockNoteRepository;
  late MockCourseRepository mockCourseRepository;
  late MockResourceRepository mockResourceRepository;
  late MockCategoryRepository mockCategoryRepository;
  late NoteBloc noteBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    mockCourseRepository = MockCourseRepository();
    mockResourceRepository = MockResourceRepository();
    mockCategoryRepository = MockCategoryRepository();
    noteBloc = NoteBloc(
      noteRepository: mockNoteRepository,
      homeworkRepository: MockHomeworkRepository(),
      eventRepository: MockEventRepository(),
      resourceRepository: mockResourceRepository,
      courseRepository: mockCourseRepository,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    noteBloc.close();
  });

  void givenUpdateFails(HeliumException exception) {
    when(
      () => mockNoteRepository.updateNote(
        noteId: any(named: 'noteId'),
        request: any(named: 'request'),
        version: any(named: 'version'),
      ),
    ).thenThrow(exception);
  }

  group('UpdateNoteEvent', () {
    blocTest<NoteBloc, NoteState>(
      'passes the version through to the repository',
      build: () {
        when(
          () => mockNoteRepository.updateNote(
            noteId: 1,
            request: any(named: 'request'),
            version: version,
          ),
        ).thenAnswer((_) async => NoteModel.fromJson(givenNoteJson()));
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        UpdateNoteEvent(
          origin: EventOrigin.subScreen,
          noteId: 1,
          request: NoteRequestModel(title: 'Note'),
          version: version,
        ),
      ),
      expect: () => [isA<NotesLoading>(), isA<NoteUpdated>()],
    );

    blocTest<NoteBloc, NoteState>(
      'emits NoteConflict with the latest note when the save is stale',
      build: () {
        givenUpdateFails(
          ConflictException(latest: givenNoteJson(title: 'Changed elsewhere')),
        );
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        UpdateNoteEvent(
          origin: EventOrigin.subScreen,
          noteId: 1,
          request: NoteRequestModel(title: 'Mine'),
          version: version,
        ),
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteConflict>()
            .having((s) => s.noteId, 'noteId', 1)
            .having((s) => s.latest.title, 'latest title', 'Changed elsewhere'),
      ],
    );

    blocTest<NoteBloc, NoteState>(
      'emits NoteMissing when the note was deleted elsewhere',
      build: () {
        givenUpdateFails(NotFoundException(message: 'Item not found.'));
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        UpdateNoteEvent(
          origin: EventOrigin.subScreen,
          noteId: 1,
          request: NoteRequestModel(title: 'Mine'),
          version: version,
        ),
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteMissing>().having((s) => s.noteId, 'noteId', 1),
      ],
    );
  });

  group('RefreshNoteEvent', () {
    blocTest<NoteBloc, NoteState>(
      'emits NoteRefreshed from a forced read without a loading state',
      build: () {
        when(
          () => mockNoteRepository.getNote(id: 1, forceRefresh: true),
        ).thenAnswer((_) async => NoteModel.fromJson(givenNoteJson()));
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        RefreshNoteEvent(origin: EventOrigin.subScreen, noteId: 1),
      ),
      expect: () => [
        isA<NoteRefreshed>().having((s) => s.note.version, 'version', version),
      ],
    );

    blocTest<NoteBloc, NoteState>(
      'emits nothing when the background read fails',
      build: () {
        when(
          () => mockNoteRepository.getNote(id: 1, forceRefresh: true),
        ).thenThrow(NetworkException(message: 'offline'));
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        RefreshNoteEvent(origin: EventOrigin.subScreen, noteId: 1),
      ),
      expect: () => <NoteState>[],
    );
  });

  group('FetchNotebookScreenDataEvent', () {
    void givenScreenData({bool shownOnCalendar = false}) {
      final groupsShown = shownOnCalendar ? true : null;
      when(
        () => mockNoteRepository.getNotes(shownOnCalendar: shownOnCalendar),
      ).thenAnswer((_) async => [NoteModel.fromJson(givenNoteJson())]);
      when(
        () =>
            mockCourseRepository.getCourseGroups(shownOnCalendar: groupsShown),
      ).thenAnswer((_) async => MockModels.createCourseGroups());
      when(
        () => mockCourseRepository.getCourses(shownOnCalendar: groupsShown),
      ).thenAnswer((_) async => MockModels.createCourses());
      when(
        () => mockResourceRepository.getResources(shownOnCalendar: groupsShown),
      ).thenAnswer(
        (_) async => [
          MockModels.createResource(courses: [1]),
        ],
      );
      when(
        () => mockCategoryRepository.getCategories(shownOnCalendar: groupsShown),
      ).thenAnswer((_) async => MockModels.createCategories());
    }

    blocTest<NoteBloc, NoteState>(
      'loads notes with every group\'s classes and resources',
      build: () {
        givenScreenData();
        return noteBloc;
      },
      act: (bloc) =>
          bloc.add(FetchNotebookScreenDataEvent(origin: EventOrigin.screen)),
      expect: () => [
        isA<NotesLoading>(),
        isA<NotebookScreenDataFetched>()
            .having((s) => s.notes.length, 'notes', 1)
            .having((s) => s.courseGroups.length, 'courseGroups', 2)
            .having((s) => s.courses.length, 'courses', 3)
            .having((s) => s.resources.single.courses, 'resource classes', [1])
            .having(
              (s) => s.categories.length,
              'categories, to colour moved assignments\' notes',
              MockModels.createCategories().length,
            ),
      ],
    );

    blocTest<NoteBloc, NoteState>(
      'loads only visible groups\' notes, classes, and resources when hidden groups are hidden',
      build: () {
        givenScreenData(shownOnCalendar: true);
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        FetchNotebookScreenDataEvent(
          origin: EventOrigin.screen,
          shownOnCalendar: true,
        ),
      ),
      expect: () => [isA<NotesLoading>(), isA<NotebookScreenDataFetched>()],
      verify: (_) {
        verify(
          () => mockNoteRepository.getNotes(shownOnCalendar: true),
        ).called(1);
        verify(
          () => mockCourseRepository.getCourses(shownOnCalendar: true),
        ).called(1);
        verify(
          () => mockResourceRepository.getResources(shownOnCalendar: true),
        ).called(1);
        verify(
          () => mockCategoryRepository.getCategories(shownOnCalendar: true),
        ).called(1);
      },
    );

    blocTest<NoteBloc, NoteState>(
      'emits an error for the screen when a fetch fails',
      build: () {
        givenScreenData();
        when(
          () => mockCourseRepository.getCourses(shownOnCalendar: null),
        ).thenThrow(ServerException(message: 'Server error'));
        return noteBloc;
      },
      act: (bloc) =>
          bloc.add(FetchNotebookScreenDataEvent(origin: EventOrigin.screen)),
      expect: () => [
        isA<NotesLoading>(),
        isA<NotesError>()
            .having((e) => e.origin, 'origin', EventOrigin.screen)
            .having((e) => e.message, 'message', 'Server error'),
      ],
    );
  });

  group('SearchNoteContentEvent', () {
    blocTest<NoteBloc, NoteState>(
      'emits [NotesLoading, NoteContentSearched] with the search it answers',
      build: () {
        when(
          () => mockNoteRepository.getNotes(
            search: 'mitosis',
            shownOnCalendar: true,
          ),
        ).thenAnswer((_) async => [NoteModel.fromJson(givenNoteJson())]);
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        SearchNoteContentEvent(
          origin: EventOrigin.subScreen,
          search: 'mitosis',
          shownOnCalendar: true,
        ),
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteContentSearched>()
            .having((s) => s.search, 'search', 'mitosis')
            .having((s) => s.notes.length, 'notes', 1)
            .having((s) => s.origin, 'origin', EventOrigin.subScreen),
      ],
    );

    blocTest<NoteBloc, NoteState>(
      'emits an error for the search when it fails',
      build: () {
        when(
          () => mockNoteRepository.getNotes(search: 'mitosis'),
        ).thenThrow(ServerException(message: 'Server error'));
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        SearchNoteContentEvent(
          origin: EventOrigin.subScreen,
          search: 'mitosis',
        ),
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NotesError>()
            .having((e) => e.origin, 'origin', EventOrigin.subScreen)
            .having((e) => e.message, 'message', 'Server error'),
      ],
    );
  });

  group('FetchLinkableEntitiesEvent', () {
    blocTest<NoteBloc, NoteState>(
      'a failed fetch reports the link picker\'s own failure',
      build: () {
        final homeworkRepository = MockHomeworkRepository();
        when(
          () => homeworkRepository.getHomeworks(),
        ).thenThrow(NetworkException(message: 'offline'));
        return NoteBloc(
          noteRepository: mockNoteRepository,
          homeworkRepository: homeworkRepository,
          eventRepository: MockEventRepository(),
          resourceRepository: mockResourceRepository,
          courseRepository: mockCourseRepository,
          categoryRepository: MockCategoryRepository(),
        );
      },
      act: (bloc) => bloc.add(
        FetchLinkableEntitiesEvent(origin: EventOrigin.subScreen),
      ),
      expect: () => [isA<LinkableEntitiesFailed>()],
    );

    blocTest<NoteBloc, NoteState>(
      'offers only visible groups\' assignments, classes, and resources without another note',
      build: () {
        final homeworkRepository = MockHomeworkRepository();
        final eventRepository = MockEventRepository();
        final categoryRepository = MockCategoryRepository();
        when(() => homeworkRepository.getHomeworks(shownOnCalendar: true))
            .thenAnswer((_) async => [MockModels.createHomework(id: 30)]);
        when(() => eventRepository.getEvents()).thenAnswer((_) async => []);
        when(() => mockResourceRepository.getResources(shownOnCalendar: true)).thenAnswer(
          (_) async => [
            MockModels.createResource(id: 40),
            MockModels.createResource(id: 41, notes: [99]),
          ],
        );
        when(() => mockResourceRepository.getResourceGroups())
            .thenAnswer((_) async => [MockModels.createResourceGroup(id: 1)]);
        when(() => categoryRepository.getCategories(shownOnCalendar: true))
            .thenAnswer((_) async => []);
        when(() => mockCourseRepository.getCourseGroups())
            .thenAnswer((_) async => [MockModels.createCourseGroup(id: 1)]);
        when(() => mockCourseRepository.getCourses(shownOnCalendar: true)).thenAnswer(
          (_) async => [
            MockModels.createCourse(id: 10),
            MockModels.createCourse(id: 11, notes: [99]),
            MockModels.createCourse(id: 12, notes: [5]),
          ],
        );
        return NoteBloc(
          noteRepository: mockNoteRepository,
          homeworkRepository: homeworkRepository,
          eventRepository: eventRepository,
          resourceRepository: mockResourceRepository,
          courseRepository: mockCourseRepository,
          categoryRepository: categoryRepository,
        );
      },
      act: (bloc) => bloc.add(
        FetchLinkableEntitiesEvent(origin: EventOrigin.subScreen, currentNoteId: 5),
      ),
      expect: () => [
        isA<LinkableEntitiesFetched>()
            .having((s) => s.homework.map((h) => h.id).toList(), 'assignments', [30])
            .having((s) => s.resources.map((r) => r.id).toList(), 'resources', [40])
            .having(
              (s) => s.linkableCourses.map((c) => c.id).toList(),
              'linkable classes, including this note\'s own',
              [10, 12],
            )
            .having((s) => s.courses.length, 'every visible class, for assignments', 3),
      ],
      verify: (_) {
        verify(() => mockResourceRepository.getResources(shownOnCalendar: true)).called(1);
        verify(() => mockCourseRepository.getCourses(shownOnCalendar: true)).called(1);
      },
    );
  });

  group('FetchNoteScreenDataEvent', () {
    blocTest<NoteBloc, NoteState>(
      'a new note opened for a class is pre-linked to it',
      build: () {
        when(() => mockCourseRepository.getCourses(id: 10)).thenAnswer(
          (_) async => [
            MockModels.createCourse(
              id: 10,
              title: 'Biology',
              color: const Color(0xFF123456),
            ),
          ],
        );
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        FetchNoteScreenDataEvent(origin: EventOrigin.subScreen, linkCourseId: 10),
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteScreenDataFetched>()
            .having((s) => s.linkedEntityType, 'type', 'course')
            .having((s) => s.linkedEntityTitle, 'title', 'Biology')
            .having((s) => s.linkedEntityColor, 'color', const Color(0xFF123456))
            .having((s) => s.matches(linkCourseId: 10), 'matches its request', isTrue),
      ],
    );
  });
}
