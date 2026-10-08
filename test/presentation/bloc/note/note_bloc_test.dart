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
      'keeps a stale linked-note save as a standalone copy when asked',
      build: () {
        givenUpdateFails(ConflictException(latest: givenNoteJson()));
        when(
          () => mockNoteRepository.createNote(request: any(named: 'request')),
        ).thenAnswer(
          (_) async => NoteModel.fromJson(givenNoteJson(id: 9, title: 'Copy')),
        );
        return noteBloc;
      },
      act: (bloc) => bloc.add(
        UpdateNoteEvent(
          origin: EventOrigin.subScreen,
          noteId: 1,
          request: NoteRequestModel(content: {'ops': []}),
          version: version,
          copyTitleOnConflict: 'Textbook (copy from this device)',
        ),
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteCreated>().having((s) => s.note.id, 'copy id', 9),
        isA<NoteSavedAsCopy>()
            .having((s) => s.noteId, 'noteId', 1)
            .having((s) => s.copy.id, 'copy id', 9),
      ],
      verify: (_) {
        final request = verify(
          () => mockNoteRepository.createNote(
            request: captureAny(named: 'request'),
          ),
        ).captured.single as NoteRequestModel;
        expect(request.title, 'Textbook (copy from this device)');
        expect(
          request.homeworkId ?? request.eventId ?? request.resourceId,
          isNull,
          reason: 'The copy is standalone; an entity can only have one note',
        );
      },
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
