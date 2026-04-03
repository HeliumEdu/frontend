// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

class PlannerItemBloc extends Bloc<PlannerItemEvent, PlannerItemState> {
  final EventRepository eventRepository;
  final HomeworkRepository homeworkRepository;
  final CourseRepository courseRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final CategoryRepository categoryRepository;
  final ResourceRepository resourceRepository;
  final NoteRepository noteRepository;

  PlannerItemBloc({
    required this.eventRepository,
    required this.homeworkRepository,
    required this.courseRepository,
    required this.categoryRepository,
    required this.courseScheduleRepository,
    required this.resourceRepository,
    required this.noteRepository,
  }) : super(PlannerItemInitial(origin: EventOrigin.bloc)) {
    on<FetchPlannerItemScreenDataEvent>(_onFetchPlannerItemScreenDataEvent);
    on<FetchEventEvent>(_onFetchEvent);
    on<CreateEventEvent>(_onCreateEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<DeleteAllEventsEvent>(_onDeleteAllEvents);
    on<FetchHomeworkEvent>(_onFetchHomework);
    on<CreateHomeworkEvent>(_onCreateHomework);
    on<UpdateHomeworkEvent>(_onUpdateHomework);
    on<DeleteHomeworkEvent>(_onDeleteHomework);
  }

  Future<void> _onFetchPlannerItemScreenDataEvent(
    FetchPlannerItemScreenDataEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final PlannerItemBaseModel? plannerItem;
      final List<CourseGroupModel> courseGroups;
      final List<CourseModel> courses;
      final List<CourseScheduleModel> courseSchedules;
      final List<CategoryModel> categories;
      final List<ResourceModel> resources;
      NoteModel? linkedNote;

      if (event.eventId != null) {
        final results = await Future.wait([
          eventRepository.getEvent(id: event.eventId!),
          noteRepository.getNotes(eventId: event.eventId, includeContent: true),
        ]);
        plannerItem = results[0] as PlannerItemBaseModel;
        final notes = results[1] as List<NoteModel>;
        linkedNote = notes.isNotEmpty ? notes.first : null;
        courseGroups = [];
        courses = [];
        courseSchedules = [];
        categories = [];
        resources = [];
      } else {
        final results = await Future.wait([
          event.homeworkId != null
              ? homeworkRepository.getHomework(id: event.homeworkId!)
              : Future.value(null),
          courseRepository.getCourseGroups(shownOnCalendar: true),
          courseRepository.getCourses(shownOnCalendar: true),
          courseScheduleRepository.getCourseSchedules(shownOnCalendar: true),
          categoryRepository.getCategories(shownOnCalendar: true),
          resourceRepository.getResources(shownOnCalendar: true),
          event.homeworkId != null
              ? noteRepository.getNotes(homeworkId: event.homeworkId, includeContent: true)
              : Future.value(<NoteModel>[]),
        ]);
        plannerItem = results[0] as PlannerItemBaseModel?;
        courseGroups = results[1] as List<CourseGroupModel>;
        courses = results[2] as List<CourseModel>;
        courseSchedules = results[3] as List<CourseScheduleModel>;
        categories = results[4] as List<CategoryModel>;
        resources = results[5] as List<ResourceModel>;
        final notes = results[6] as List<NoteModel>;
        linkedNote = notes.isNotEmpty ? notes.first : null;
      }

      emit(
        PlannerItemScreenDataFetched(
          origin: event.origin,
          plannerItem: plannerItem,
          courseGroups: courseGroups,
          courses: courses,
          courseSchedules: courseSchedules,
          categories: categories,
          resources: resources,
          linkedNote: linkedNote,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onFetchEvent(
    FetchEventEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final entity = await eventRepository.getEvent(id: event.eventId);
      emit(
        EventFetched(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final entity = await eventRepository.createEvent(request: event.request);

      // Create linked note if content provided
      int? linkedNoteId;
      if (event.noteContent != null) {
        final note = await noteRepository.createNote(
          request: NoteRequestModel(
            content: event.noteContent,
            eventId: entity.id,
          ),
        );
        linkedNoteId = note.id;
      }

      emit(
        EventCreated(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          isClone: event.isClone,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteId,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      // Update entity and note in parallel
      final futures = <Future<dynamic>>[
        eventRepository.updateEvent(eventId: event.id, request: event.request),
      ];

      int? linkedNoteId = event.linkedNoteId;
      if (event.linkedNoteId != null) {
        // Empty content triggers note deletion on backend
        final contentToSend = event.noteContent ?? <String, dynamic>{};
        futures.add(noteRepository.updateNote(
          noteId: event.linkedNoteId!,
          request: NoteRequestModel(content: contentToSend),
        ));
        if (event.noteContent == null) linkedNoteId = null;
      } else if (event.noteContent != null) {
        futures.add(noteRepository.createNote(
          request: NoteRequestModel(content: event.noteContent, eventId: event.id),
        ));
      }

      final results = await Future.wait(futures);
      final entity = results[0] as EventModel;

      if (event.linkedNoteId == null && results.length > 1) {
        linkedNoteId = (results[1] as NoteModel).id;
      }

      emit(
        EventUpdated(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteId,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      await eventRepository.deleteEvent(eventId: event.id);
      emit(EventDeleted(origin: event.origin, id: event.id));
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onDeleteAllEvents(
    DeleteAllEventsEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      await eventRepository.deleteAllEvents();
      emit(AllEventsDeleted(origin: event.origin));
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onFetchHomework(
    FetchHomeworkEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final homework = await homeworkRepository.getHomework(id: event.id);
      emit(
        HomeworkFetched(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onCreateHomework(
    CreateHomeworkEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final homework = await homeworkRepository.createHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        request: event.request,
      );

      // Create linked note if content provided
      int? linkedNoteId;
      if (event.noteContent != null) {
        final note = await noteRepository.createNote(
          request: NoteRequestModel(
            content: event.noteContent,
            homeworkId: homework.id,
          ),
        );
        linkedNoteId = note.id;
      }

      emit(
        HomeworkCreated(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          isClone: event.isClone,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteId,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onUpdateHomework(
    UpdateHomeworkEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      // Update entity and note in parallel
      final futures = <Future<dynamic>>[
        homeworkRepository.updateHomework(
          groupId: event.courseGroupId,
          courseId: event.courseId,
          homeworkId: event.homeworkId,
          request: event.request,
        ),
      ];

      int? linkedNoteId = event.linkedNoteId;
      if (event.linkedNoteId != null) {
        // Empty content triggers note deletion on backend
        final contentToSend = event.noteContent ?? <String, dynamic>{};
        futures.add(noteRepository.updateNote(
          noteId: event.linkedNoteId!,
          request: NoteRequestModel(content: contentToSend),
        ));
        if (event.noteContent == null) linkedNoteId = null;
      } else if (event.noteContent != null) {
        futures.add(noteRepository.createNote(
          request: NoteRequestModel(content: event.noteContent, homeworkId: event.homeworkId),
        ));
      }

      final results = await Future.wait(futures);
      final homework = results[0] as HomeworkModel;

      if (event.linkedNoteId == null && results.length > 1) {
        linkedNoteId = (results[1] as NoteModel).id;
      }

      emit(
        HomeworkUpdated(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteId,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onDeleteHomework(
    DeleteHomeworkEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      await homeworkRepository.deleteHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
      );
      emit(HomeworkDeleted(origin: event.origin, id: event.homeworkId));
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }
}
