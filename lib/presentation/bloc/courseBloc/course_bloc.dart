// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/domain/repositories/course_repository.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository courseRepository;

  CourseBloc({required this.courseRepository}) : super(CourseInitial()) {
    on<FetchCoursesEvent>(_onFetchCourses);
    on<FetchCoursesByGroupEvent>(_onFetchCoursesByGroup);
    on<FetchCourseByIdEvent>(_onFetchCourseById);
    on<CreateCourseEvent>(_onCreateCourse);
    on<UpdateCourseEvent>(_onUpdateCourse);
    on<DeleteCourseEvent>(_onDeleteCourse);
    on<CreateCourseScheduleEvent>(_onCreateCourseSchedule);
    on<UpdateCourseScheduleEvent>(_onUpdateCourseSchedule);
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<UploadAttachmentsEvent>(_onUploadAttachments);
    on<FetchAttachmentsEvent>(_onFetchAttachments);
    on<DeleteAttachmentEvent>(_onDeleteAttachment);
    on<FetchCourseGroupsEvent>(_onFetchCourseGroups);
    on<CreateCourseGroupEvent>(_onCreateCourseGroup);
    on<UpdateCourseGroupEvent>(_onUpdateCourseGroup);
    on<DeleteCourseGroupEvent>(_onDeleteCourseGroup);
  }

  Future<void> _onFetchCourses(
    FetchCoursesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());

    try {
      final courses = await courseRepository.getCourses();
      emit(CourseLoaded(courses: courses));
    } on NetworkException catch (e) {
      emit(CourseError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseError(message: e.message));
    } on AppException catch (e) {
      emit(CourseError(message: e.message));
    } catch (e) {
      emit(CourseError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchCoursesByGroup(
    FetchCoursesByGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());

    try {
      final courses = await courseRepository.getCoursesByGroupId(event.groupId);
      emit(CourseLoaded(courses: courses));
    } on NetworkException catch (e) {
      emit(CourseError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseError(message: e.message));
    } on AppException catch (e) {
      emit(CourseError(message: e.message));
    } catch (e) {
      emit(CourseError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchCourseById(
    FetchCourseByIdEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseDetailLoading());

    try {
      final course = await courseRepository.getCourseById(
        event.groupId,
        event.courseId,
      );
      emit(CourseDetailLoaded(course: course));
    } on NetworkException catch (e) {
      emit(CourseDetailError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseDetailError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseDetailError(message: e.message));
    } on AppException catch (e) {
      emit(CourseDetailError(message: e.message));
    } catch (e) {
      emit(CourseDetailError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCreateCourse(
    CreateCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseCreating());

    try {
      final course = await courseRepository.createCourse(event.request);
      emit(CourseCreated(course: course));
    } on ValidationException catch (e) {
      emit(CourseCreateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CourseCreateError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseCreateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseCreateError(message: e.message));
    } on AppException catch (e) {
      emit(CourseCreateError(message: e.message));
    } catch (e) {
      emit(CourseCreateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onUpdateCourse(
    UpdateCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseUpdating());

    try {
      final course = await courseRepository.updateCourse(
        event.groupId,
        event.courseId,
        event.request,
      );
      emit(CourseUpdated(course: course));
    } on ValidationException catch (e) {
      emit(CourseUpdateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CourseUpdateError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseUpdateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseUpdateError(message: e.message));
    } on AppException catch (e) {
      emit(CourseUpdateError(message: e.message));
    } catch (e) {
      emit(CourseUpdateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteCourse(
    DeleteCourseEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseDeleting());

    try {
      await courseRepository.deleteCourse(event.groupId, event.courseId);
      emit(CourseDeleted(deletedCourseId: event.courseId));
    } on NetworkException catch (e) {
      emit(CourseDeleteError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseDeleteError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseDeleteError(message: e.message));
    } on AppException catch (e) {
      emit(CourseDeleteError(message: e.message));
    } catch (e) {
      emit(CourseDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCreateCourseSchedule(
    CreateCourseScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseScheduleCreating());

    try {
      final schedule = await courseRepository.createCourseSchedule(
        event.groupId,
        event.courseId,
        event.request,
      );
      emit(CourseScheduleCreated(schedule: schedule));
    } on ValidationException catch (e) {
      emit(CourseScheduleCreateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CourseScheduleCreateError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseScheduleCreateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseScheduleCreateError(message: e.message));
    } on AppException catch (e) {
      emit(CourseScheduleCreateError(message: e.message));
    } catch (e) {
      emit(
        CourseScheduleCreateError(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  Future<void> _onUpdateCourseSchedule(
    UpdateCourseScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseScheduleUpdating());

    try {
      final schedule = await courseRepository.updateCourseSchedule(
        event.groupId,
        event.courseId,
        event.scheduleId,
        event.request,
      );
      emit(CourseScheduleUpdated(schedule: schedule));
    } on ValidationException catch (e) {
      emit(CourseScheduleUpdateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CourseScheduleUpdateError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseScheduleUpdateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseScheduleUpdateError(message: e.message));
    } on AppException catch (e) {
      emit(CourseScheduleUpdateError(message: e.message));
    } catch (e) {
      emit(
        CourseScheduleUpdateError(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CategoriesLoading());

    try {
      final categories = await courseRepository.getCategoriesByCourse(
        event.groupId,
        event.courseId,
      );
      emit(CategoriesLoaded(categories: categories));
    } on NetworkException catch (e) {
      emit(CategoriesError(message: e.message));
    } on ServerException catch (e) {
      emit(CategoriesError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CategoriesError(message: e.message));
    } on AppException catch (e) {
      emit(CategoriesError(message: e.message));
    } catch (e) {
      emit(CategoriesError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CategoryCreating());

    try {
      final category = await courseRepository.createCategory(
        event.groupId,
        event.courseId,
        event.request,
      );
      emit(CategoryCreated(category: category));
    } on ValidationException catch (e) {
      emit(CategoryCreateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CategoryCreateError(message: e.message));
    } on ServerException catch (e) {
      emit(CategoryCreateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CategoryCreateError(message: e.message));
    } on AppException catch (e) {
      emit(CategoryCreateError(message: e.message));
    } catch (e) {
      emit(CategoryCreateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CategoryUpdating());

    try {
      final category = await courseRepository.updateCategory(
        event.groupId,
        event.courseId,
        event.categoryId,
        event.request,
      );
      emit(CategoryUpdated(category: category));
    } on ValidationException catch (e) {
      emit(CategoryUpdateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CategoryUpdateError(message: e.message));
    } on ServerException catch (e) {
      emit(CategoryUpdateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CategoryUpdateError(message: e.message));
    } on AppException catch (e) {
      emit(CategoryUpdateError(message: e.message));
    } catch (e) {
      emit(CategoryUpdateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CategoryDeleting());

    try {
      await courseRepository.deleteCategory(
        event.groupId,
        event.courseId,
        event.categoryId,
      );
      emit(CategoryDeleted(deletedCategoryId: event.categoryId));
    } on NetworkException catch (e) {
      emit(CategoryDeleteError(message: e.message));
    } on ServerException catch (e) {
      emit(CategoryDeleteError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CategoryDeleteError(message: e.message));
    } on AppException catch (e) {
      emit(CategoryDeleteError(message: e.message));
    } catch (e) {
      emit(CategoryDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onUploadAttachments(
    UploadAttachmentsEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(AttachmentsUploading());

    try {
      // Validate that at least one of course, event, or homework is provided
      if (event.courseId == null &&
          event.eventId == null &&
          event.homeworkId == null) {
        throw ValidationException(
          message: 'At least one of class, event, or homework must be provided',
        );
      }

      final attachments = await courseRepository.uploadAttachments(
        files: event.files,
        courseId: event.courseId,
        eventId: event.eventId,
        homeworkId: event.homeworkId,
      );
      emit(AttachmentsUploaded(attachments: attachments));
    } on ValidationException catch (e) {
      emit(AttachmentsUploadError(message: e.message));
    } on NetworkException catch (e) {
      emit(AttachmentsUploadError(message: e.message));
    } on ServerException catch (e) {
      emit(AttachmentsUploadError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(AttachmentsUploadError(message: e.message));
    } on AppException catch (e) {
      emit(AttachmentsUploadError(message: e.message));
    } catch (e) {
      emit(AttachmentsUploadError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchAttachments(
    FetchAttachmentsEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(AttachmentsLoading());

    try {
      final attachments = await courseRepository.getAttachments(
        courseId: event.courseId,
        eventId: event.eventId,
        homeworkId: event.homeworkId,
      );
      emit(AttachmentsLoaded(attachments: attachments));
    } on NetworkException catch (e) {
      emit(AttachmentsError(message: e.message));
    } on ServerException catch (e) {
      emit(AttachmentsError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(AttachmentsError(message: e.message));
    } on AppException catch (e) {
      emit(AttachmentsError(message: e.message));
    } catch (e) {
      emit(AttachmentsError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteAttachment(
    DeleteAttachmentEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(AttachmentDeleting());

    try {
      await courseRepository.deleteAttachment(event.attachmentId);
      emit(AttachmentDeleted());
    } on NetworkException catch (e) {
      emit(AttachmentDeleteError(message: e.message));
    } on ServerException catch (e) {
      emit(AttachmentDeleteError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(AttachmentDeleteError(message: e.message));
    } on AppException catch (e) {
      emit(AttachmentDeleteError(message: e.message));
    } catch (e) {
      emit(AttachmentDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchCourseGroups(
    FetchCourseGroupsEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseGroupsLoading());

    try {
      final courseGroups = await courseRepository.getCourseGroups();
      emit(CourseGroupsLoaded(courseGroups: courseGroups));
    } on NetworkException catch (e) {
      emit(CourseGroupsError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseGroupsError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseGroupsError(message: e.message));
    } on AppException catch (e) {
      emit(CourseGroupsError(message: e.message));
    } catch (e) {
      emit(CourseGroupsError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCreateCourseGroup(
    CreateCourseGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseGroupCreating());

    try {
      final courseGroup = await courseRepository.createCourseGroup(
        event.request,
      );
      emit(CourseGroupCreated(courseGroup: courseGroup));
    } on ValidationException catch (e) {
      emit(CourseGroupCreateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CourseGroupCreateError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseGroupCreateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseGroupCreateError(message: e.message));
    } on AppException catch (e) {
      emit(CourseGroupCreateError(message: e.message));
    } catch (e) {
      emit(CourseGroupCreateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onUpdateCourseGroup(
    UpdateCourseGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseGroupUpdating());

    try {
      final courseGroup = await courseRepository.updateCourseGroup(
        event.groupId,
        event.request,
      );
      emit(CourseGroupUpdated(courseGroup: courseGroup));
    } on ValidationException catch (e) {
      emit(CourseGroupUpdateError(message: e.message));
    } on NetworkException catch (e) {
      emit(CourseGroupUpdateError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseGroupUpdateError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseGroupUpdateError(message: e.message));
    } on AppException catch (e) {
      emit(CourseGroupUpdateError(message: e.message));
    } catch (e) {
      emit(CourseGroupUpdateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteCourseGroup(
    DeleteCourseGroupEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseGroupDeleting());

    try {
      await courseRepository.deleteCourseGroup(event.groupId);
      emit(CourseGroupDeleted(deletedGroupId: event.groupId));
    } on NetworkException catch (e) {
      emit(CourseGroupDeleteError(message: e.message));
    } on ServerException catch (e) {
      emit(CourseGroupDeleteError(message: e.message));
    } on UnauthorizedException catch (e) {
      emit(CourseGroupDeleteError(message: e.message));
    } on AppException catch (e) {
      emit(CourseGroupDeleteError(message: e.message));
    } catch (e) {
      emit(CourseGroupDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }
}
