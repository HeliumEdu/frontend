import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
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
import 'package:heliumapp/domain/linked_note_saver.dart';

class PlannerItemBloc extends Bloc<PlannerItemEvent, PlannerItemState> {
  final EventRepository eventRepository;
  final HomeworkRepository homeworkRepository;
  final CourseRepository courseRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final CategoryRepository categoryRepository;
  final ResourceRepository resourceRepository;
  final NoteRepository noteRepository;
  final LinkedNoteSaver _linkedNoteSaver;

  final Set<int> _deletingEventIds = {};
  final Set<int> _deletingHomeworkIds = {};

  PlannerItemBloc({
    required this.eventRepository,
    required this.homeworkRepository,
    required this.courseRepository,
    required this.categoryRepository,
    required this.courseScheduleRepository,
    required this.resourceRepository,
    required this.noteRepository,
  }) : _linkedNoteSaver = LinkedNoteSaver(noteRepository),
       super(PlannerItemInitial(origin: EventOrigin.bloc)) {
    on<FetchPlannerItemScreenDataEvent>(_onFetchPlannerItemScreenDataEvent);
    on<CreateEventEvent>(_onCreateEvent);
    on<CloneEventEvent>(_onCloneEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<DeleteAllEventsEvent>(_onDeleteAllEvents);
    on<CreateHomeworkEvent>(_onCreateHomework);
    on<CloneHomeworkEvent>(_onCloneHomework);
    on<UpdateHomeworkEvent>(_onUpdateHomework);
    on<DeleteHomeworkEvent>(_onDeleteHomework);
    on<ResetPlannerItemsEvent>(
      (event, emit) => emit(PlannerItemInitial(origin: EventOrigin.bloc)),
    );
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
      CourseModel? itemCourse;

      if (event.eventId != null) {
        final results = await Future.wait([
          eventRepository.getEvent(
            id: event.eventId!,
            forceRefresh: event.forceRefresh,
          ),
          noteRepository.getNotes(
            eventId: event.eventId,
            includeContent: true,
            forceRefresh: event.forceRefresh,
          ),
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
              ? homeworkRepository.getHomework(
                  id: event.homeworkId!,
                  forceRefresh: event.forceRefresh,
                )
              : Future.value(null),
          courseRepository.getCourseGroups(shownOnCalendar: true),
          courseRepository.getCourses(shownOnCalendar: true),
          courseScheduleRepository.getCourseSchedules(shownOnCalendar: true),
          categoryRepository.getCategories(shownOnCalendar: true),
          resourceRepository.getResources(shownOnCalendar: true),
          event.homeworkId != null
              ? noteRepository.getNotes(
                  homeworkId: event.homeworkId,
                  includeContent: true,
                  forceRefresh: event.forceRefresh,
                )
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
        itemCourse = await _resolveItemCourse(plannerItem, courses);
      }

      emit(
        PlannerItemScreenDataFetched(
          origin: event.origin,
          plannerItem: plannerItem,
          homeworkId: event.homeworkId,
          eventId: event.eventId,
          courseGroups: courseGroups,
          courses: courses,
          courseSchedules: courseSchedules,
          categories: categories,
          resources: resources,
          linkedNote: linkedNote,
          itemCourse: itemCourse,
        ),
      );
    } on HeliumException catch (e) {
      emit(
        PlannerItemScreenDataFailed(
          origin: event.origin,
          message: e.message,
          homeworkId: event.homeworkId,
          eventId: event.eventId,
        ),
      );
    } catch (e) {
      emit(
        PlannerItemScreenDataFailed(
          origin: event.origin,
          message: HeliumException.unexpectedError,
          homeworkId: event.homeworkId,
          eventId: event.eventId,
        ),
      );
    }
  }

  Future<CourseModel?> _resolveItemCourse(
    PlannerItemBaseModel? plannerItem,
    List<CourseModel> courses,
  ) async {
    if (plannerItem is! HomeworkModel) return null;

    final courseId = plannerItem.course.id;
    if (courses.any((course) => course.id == courseId)) return null;

    final resolved = await courseRepository.getCourses(id: courseId);
    return resolved.isNotEmpty ? resolved.first : null;
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
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onCloneEvent(
    CloneEventEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final entity = await eventRepository.cloneEvent(eventId: event.eventId);

      emit(
        EventCreated(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
          advanceNavOnSuccess: true,
          isClone: true,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
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
      final saved = await LinkedNoteSaver.saveWithEntity(
        eventRepository.updateEvent(
          eventId: event.id,
          request: event.request,
          version: event.version,
        ),
        _linkedNoteSaver.save(
          linkedNoteId: event.linkedNoteId,
          linkedNoteVersion: event.linkedNoteVersion,
          noteEdited: event.noteEdited,
          noteContent: event.noteContent,
          eventId: event.id,
        ),
      );
      if (saved.entityConflict != null) {
        emit(PlannerItemConflict(
          origin: event.origin,
          linkedNoteSave: saved.note,
        ));
        return;
      }
      final rawEntity = saved.entity!;
      final linkedNoteId = saved.note!.noteId;

      final entity = rawEntity.copyWith(
        notes: _reconcileNotes(
          rawEntity.notes,
          previousId: event.linkedNoteId,
          currentId: linkedNoteId,
        ),
      );

      emit(
        EventUpdated(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteId,
          linkedNoteSave: saved.note,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  /// A delete cascades its reminders away server-side without pushing anything,
  /// so the bell has to be told. Cannot throw: the delete already succeeded.
  void _refreshNotificationCount() {
    unawaited(() async {
      try {
        await NotificationCountService().refresh();
      } catch (_) {}
    }());
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    if (!_deletingEventIds.add(event.id)) return;

    emit(PlannerItemsLoading(origin: event.origin));
    try {
      await eventRepository.deleteEvent(eventId: event.id);
      emit(EventDeleted(origin: event.origin, id: event.id));
      _refreshNotificationCount();
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    } finally {
      _deletingEventIds.remove(event.id);
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
          message: HeliumException.unexpectedError,
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
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onCloneHomework(
    CloneHomeworkEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    emit(PlannerItemsLoading(origin: event.origin));
    try {
      final homework = await homeworkRepository.cloneHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
      );

      emit(
        HomeworkCreated(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
          advanceNavOnSuccess: true,
          isClone: true,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
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
      final saved = await LinkedNoteSaver.saveWithEntity(
        homeworkRepository.updateHomework(
          groupId: event.courseGroupId,
          courseId: event.courseId,
          homeworkId: event.homeworkId,
          request: event.request,
          version: event.version,
        ),
        _linkedNoteSaver.save(
          linkedNoteId: event.linkedNoteId,
          linkedNoteVersion: event.linkedNoteVersion,
          noteEdited: event.noteEdited,
          noteContent: event.noteContent,
          homeworkId: event.homeworkId,
        ),
      );
      if (saved.entityConflict != null) {
        emit(PlannerItemConflict(
          origin: event.origin,
          linkedNoteSave: saved.note,
        ));
        return;
      }
      final rawHomework = saved.entity!;
      final linkedNoteId = saved.note!.noteId;

      final homework = rawHomework.copyWith(
        notes: _reconcileNotes(
          rawHomework.notes,
          previousId: event.linkedNoteId,
          currentId: linkedNoteId,
        ),
      );

      emit(
        HomeworkUpdated(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          redirectToNotebook: event.redirectToNotebook,
          linkedNoteId: linkedNoteId,
          linkedNoteSave: saved.note,
          previousHomework: event.previousHomework,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onDeleteHomework(
    DeleteHomeworkEvent event,
    Emitter<PlannerItemState> emit,
  ) async {
    if (!_deletingHomeworkIds.add(event.homeworkId)) return;

    emit(PlannerItemsLoading(origin: event.origin));
    try {
      await homeworkRepository.deleteHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
      );
      emit(HomeworkDeleted(origin: event.origin, id: event.homeworkId));
      _refreshNotificationCount();
    } on HeliumException catch (e) {
      emit(PlannerItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerItemsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    } finally {
      _deletingHomeworkIds.remove(event.homeworkId);
    }
  }

  /// Reconciles an entity's `notes` against the actual linked-note state after
  /// a parallel `Future.wait` — the entity PATCH may still list a just-deleted
  /// note or miss a just-created one.
  static List<IdOrEntity<NoteModel>> _reconcileNotes(
    List<IdOrEntity<NoteModel>> existing, {
    required int? previousId,
    required int? currentId,
  }) {
    final filtered = existing
        .where((n) => n.id != previousId && n.id != currentId)
        .toList();
    if (currentId != null) {
      filtered.add(IdOrEntity<NoteModel>(id: currentId));
    }
    return filtered;
  }
}
