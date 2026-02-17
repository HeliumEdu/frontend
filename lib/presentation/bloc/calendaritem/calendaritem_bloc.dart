// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_event.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';

class CalendarItemBloc extends Bloc<CalendarItemEvent, CalendarItemState> {
  final EventRepository eventRepository;
  final HomeworkRepository homeworkRepository;
  final CourseRepository courseRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final CategoryRepository categoryRepository;
  final ResourceRepository resourceRepository;

  CalendarItemBloc({
    required this.eventRepository,
    required this.homeworkRepository,
    required this.courseRepository,
    required this.categoryRepository,
    required this.courseScheduleRepository,
    required this.resourceRepository,
  }) : super(CalendarItemInitial(origin: EventOrigin.bloc)) {
    on<FetchCalendarItemScreenDataEvent>(_onFetchCalendarItemScreenDataEvent);
    on<FetchEventEvent>(_onFetchEvent);
    on<CreateEventEvent>(_onCreateEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<FetchHomeworkEvent>(_onFetchHomework);
    on<CreateHomeworkEvent>(_onCreateHomework);
    on<UpdateHomeworkEvent>(_onUpdateHomework);
    on<DeleteHomeworkEvent>(_onDeleteHomework);
  }

  Future<void> _onFetchCalendarItemScreenDataEvent(
    FetchCalendarItemScreenDataEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      final CalendarItemBaseModel? calendarItem;
      final List<CourseGroupModel> courseGroups;
      final List<CourseModel> courses;
      final List<CourseScheduleModel> courseSchedules;
      final List<CategoryModel> categories;
      final List<ResourceModel> resources;
      if (event.eventId != null) {
        calendarItem = await eventRepository.getEvent(id: event.eventId!);
        courseGroups = [];
        courses = [];
        courseSchedules = [];
        categories = [];
        resources = [];
      } else {
        if (event.homeworkId != null) {
          calendarItem = await homeworkRepository.getHomework(
            id: event.homeworkId!,
          );
        } else {
          calendarItem = null;
        }
        courseGroups = await courseRepository.getCourseGroups(
          shownOnCalendar: true,
        );
        courses = await courseRepository.getCourses(shownOnCalendar: true);
        courseSchedules = await courseScheduleRepository.getCourseSchedules(
          shownOnCalendar: true,
        );
        categories = await categoryRepository.getCategories(
          shownOnCalendar: true,
        );
        resources = await resourceRepository.getResources(
          shownOnCalendar: true,
        );
      }

      emit(
        CalendarItemScreenDataFetched(
          origin: event.origin,
          calendarItem: calendarItem,
          courseGroups: courseGroups,
          courses: courses,
          courseSchedules: courseSchedules,
          categories: categories,
          resources: resources,
        ),
      );
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchEvent(
    FetchEventEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
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
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      final entity = await eventRepository.createEvent(request: event.request);
      emit(
        EventCreated(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          isClone: event.isClone,
        ),
      );
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      final entity = await eventRepository.updateEvent(
        eventId: event.id,
        request: event.request,
      );
      emit(
        EventUpdated(
          origin: event.origin,
          event: entity,
          entityId: entity.id,
          isEvent: true,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
        ),
      );
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      await eventRepository.deleteEvent(eventId: event.id);
      emit(EventDeleted(origin: event.origin, id: event.id));
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchHomework(
    FetchHomeworkEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
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
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateHomework(
    CreateHomeworkEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      final homework = await homeworkRepository.createHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        request: event.request,
      );
      emit(
        HomeworkCreated(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
          isClone: event.isClone,
        ),
      );
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateHomework(
    UpdateHomeworkEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      final homework = await homeworkRepository.updateHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
        request: event.request,
      );
      emit(
        HomeworkUpdated(
          origin: event.origin,
          homework: homework,
          entityId: homework.id,
          isEvent: false,
          advanceNavOnSuccess: event.advanceNavOnSuccess,
        ),
      );
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteHomework(
    DeleteHomeworkEvent event,
    Emitter<CalendarItemState> emit,
  ) async {
    emit(CalendarItemsLoading(origin: event.origin));
    try {
      await homeworkRepository.deleteHomework(
        groupId: event.courseGroupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
      );
      emit(HomeworkDeleted(origin: event.origin, id: event.homeworkId));
    } on HeliumException catch (e) {
      emit(CalendarItemsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CalendarItemsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}
