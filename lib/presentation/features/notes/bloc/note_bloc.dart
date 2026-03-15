// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteRepository noteRepository;

  NoteBloc({required this.noteRepository})
      : super(NoteInitial(origin: EventOrigin.bloc)) {
    on<FetchNotesEvent>(_onFetchNotes);
    on<FetchNoteEvent>(_onFetchNote);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
  }

  Future<void> _onFetchNotes(
    FetchNotesEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NotesLoading(origin: event.origin));
    try {
      final notes = await noteRepository.getNotes(
        search: event.search,
        linkedEntityType: event.linkedEntityType,
        forceRefresh: event.forceRefresh,
      );
      emit(NotesFetched(origin: event.origin, notes: notes));
    } on HeliumException catch (e) {
      emit(NotesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(NotesError(
        origin: event.origin,
        message: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> _onFetchNote(
    FetchNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NotesLoading(origin: event.origin));
    try {
      final note = await noteRepository.getNote(
        id: event.noteId,
        forceRefresh: event.forceRefresh,
      );
      emit(NoteFetched(origin: event.origin, note: note));
    } on HeliumException catch (e) {
      emit(NotesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(NotesError(
        origin: event.origin,
        message: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> _onCreateNote(
    CreateNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NotesLoading(origin: event.origin));
    try {
      final note = await noteRepository.createNote(request: event.request);
      emit(NoteCreated(origin: event.origin, note: note));
    } on HeliumException catch (e) {
      emit(NotesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(NotesError(
        origin: event.origin,
        message: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NotesLoading(origin: event.origin));
    try {
      final note = await noteRepository.updateNote(
        noteId: event.noteId,
        request: event.request,
      );
      if (note == null) {
        // Note was deleted because content was cleared on a linked note
        emit(NoteDeleted(origin: event.origin, noteId: event.noteId));
      } else {
        emit(NoteUpdated(origin: event.origin, note: note));
      }
    } on HeliumException catch (e) {
      emit(NotesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(NotesError(
        origin: event.origin,
        message: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> _onDeleteNote(
    DeleteNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NotesLoading(origin: event.origin));
    try {
      await noteRepository.deleteNote(noteId: event.noteId);
      emit(NoteDeleted(origin: event.origin, noteId: event.noteId));
    } on HeliumException catch (e) {
      emit(NotesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(NotesError(
        origin: event.origin,
        message: 'An unexpected error occurred.',
      ));
    }
  }
}
