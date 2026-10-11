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
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  const version = '2026-10-07T12:00:00.123456Z';
  late MockNoteRepository mockNoteRepository;
  late NoteBloc noteBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    noteBloc = NoteBloc(
      noteRepository: mockNoteRepository,
      homeworkRepository: MockHomeworkRepository(),
      eventRepository: MockEventRepository(),
      resourceRepository: MockResourceRepository(),
      courseRepository: MockCourseRepository(),
      categoryRepository: MockCategoryRepository(),
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
}
