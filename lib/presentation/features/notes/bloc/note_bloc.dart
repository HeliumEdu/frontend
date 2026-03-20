// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteRepository noteRepository;
  final HomeworkRepository homeworkRepository;
  final EventRepository eventRepository;
  final ResourceRepository resourceRepository;
  final CourseRepository courseRepository;

  NoteBloc({
    required this.noteRepository,
    required this.homeworkRepository,
    required this.eventRepository,
    required this.resourceRepository,
    required this.courseRepository,
  }) : super(NoteInitial(origin: EventOrigin.bloc)) {
    on<FetchNotesEvent>(_onFetchNotes);
    on<FetchNoteEvent>(_onFetchNote);
    on<FetchNoteScreenDataEvent>(_onFetchNoteScreenData);
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

  Future<void> _onFetchNoteScreenData(
    FetchNoteScreenDataEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NotesLoading(origin: event.origin));
    try {
      if (event.noteId != null) {
        final note = await noteRepository.getNote(
          id: event.noteId!,
          forceRefresh: true,
        );
        emit(NoteScreenDataFetched(
          origin: event.origin,
          note: note,
          linkedEntityType: note.linkedEntityType,
          linkedEntityTitle: note.linkedEntityTitle,
          linkedEntityColor: note.courseColor ?? note.categoryColor,
        ));
        return;
      }

      if (event.homeworkId != null) {
        final results = await Future.wait([
          homeworkRepository.getHomework(id: event.homeworkId!),
          courseRepository.getCourses(),
        ]);
        final homework = results[0] as dynamic;
        final courses = results[1] as List<CourseModel>;
        final course = courses.cast<CourseModel?>().firstWhere(
          (c) => c?.id == homework.course.id,
          orElse: () => null,
        );
        emit(NoteScreenDataFetched(
          origin: event.origin,
          linkedEntityType: 'homework',
          linkedEntityTitle: homework.label as String,
          linkedEntityColor: course?.color,
        ));
        return;
      }

      if (event.eventId != null) {
        final entity = await eventRepository.getEvent(id: event.eventId!);
        emit(NoteScreenDataFetched(
          origin: event.origin,
          linkedEntityType: 'event',
          linkedEntityTitle: entity.title,
        ));
        return;
      }

      if (event.resourceId != null && event.resourceGroupId != null) {
        final resource = await resourceRepository.getResource(
          groupId: event.resourceGroupId!,
          resourceId: event.resourceId!,
        );
        emit(NoteScreenDataFetched(
          origin: event.origin,
          linkedEntityType: 'resource',
          linkedEntityTitle: resource.title,
        ));
        return;
      }

      emit(NoteScreenDataFetched(origin: event.origin));
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
