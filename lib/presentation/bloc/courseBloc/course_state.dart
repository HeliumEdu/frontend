import 'package:heliumedu/data/models/planner/course_model.dart';
import 'package:heliumedu/data/models/planner/course_schedule_model.dart';
import 'package:heliumedu/data/models/planner/category_model.dart';
import 'package:heliumedu/data/models/planner/attachment_model.dart';
import 'package:heliumedu/data/models/planner/course_group_response_model.dart';

abstract class CourseState {}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<CourseModel> courses;

  CourseLoaded({required this.courses});
}

class CourseError extends CourseState {
  final String message;

  CourseError({required this.message});
}

// Fetch Course by ID States
class CourseDetailLoading extends CourseState {}

class CourseDetailLoaded extends CourseState {
  final CourseModel course;

  CourseDetailLoaded({required this.course});
}

class CourseDetailError extends CourseState {
  final String message;

  CourseDetailError({required this.message});
}

// Course Group States
class CourseGroupsLoading extends CourseState {}

class CourseGroupsLoaded extends CourseState {
  final List<CourseGroupResponseModel> courseGroups;

  CourseGroupsLoaded({required this.courseGroups});
}

class CourseGroupsError extends CourseState {
  final String message;

  CourseGroupsError({required this.message});
}

class CourseGroupCreating extends CourseState {}

class CourseGroupCreated extends CourseState {
  final CourseGroupResponseModel courseGroup;

  CourseGroupCreated({required this.courseGroup});
}

class CourseGroupCreateError extends CourseState {
  final String message;

  CourseGroupCreateError({required this.message});
}

class CourseGroupUpdating extends CourseState {}

class CourseGroupUpdated extends CourseState {
  final CourseGroupResponseModel courseGroup;

  CourseGroupUpdated({required this.courseGroup});
}

class CourseGroupUpdateError extends CourseState {
  final String message;

  CourseGroupUpdateError({required this.message});
}

class CourseGroupDeleting extends CourseState {}

class CourseGroupDeleted extends CourseState {
  final int deletedGroupId;

  CourseGroupDeleted({required this.deletedGroupId});
}

class CourseGroupDeleteError extends CourseState {
  final String message;

  CourseGroupDeleteError({required this.message});
}

// Course Create States
class CourseCreating extends CourseState {}

class CourseCreated extends CourseState {
  final CourseModel course;

  CourseCreated({required this.course});
}

class CourseCreateError extends CourseState {
  final String message;

  CourseCreateError({required this.message});
}

// Update Course States
class CourseUpdating extends CourseState {}

class CourseUpdated extends CourseState {
  final CourseModel course;

  CourseUpdated({required this.course});
}

class CourseUpdateError extends CourseState {
  final String message;

  CourseUpdateError({required this.message});
}

// Course Delete States
class CourseDeleting extends CourseState {}

class CourseDeleted extends CourseState {
  final int deletedCourseId;

  CourseDeleted({required this.deletedCourseId});
}

class CourseDeleteError extends CourseState {
  final String message;

  CourseDeleteError({required this.message});
}

// Course Schedule Create States
class CourseScheduleCreating extends CourseState {}

class CourseScheduleCreated extends CourseState {
  final CourseScheduleModel schedule;

  CourseScheduleCreated({required this.schedule});
}

class CourseScheduleCreateError extends CourseState {
  final String message;

  CourseScheduleCreateError({required this.message});
}

// Update Course Schedule States
class CourseScheduleUpdating extends CourseState {}

class CourseScheduleUpdated extends CourseState {
  final CourseScheduleModel schedule;

  CourseScheduleUpdated({required this.schedule});
}

class CourseScheduleUpdateError extends CourseState {
  final String message;

  CourseScheduleUpdateError({required this.message});
}

// Category States
class CategoriesLoading extends CourseState {}

class CategoriesLoaded extends CourseState {
  final List<CategoryModel> categories;

  CategoriesLoaded({required this.categories});
}

class CategoriesError extends CourseState {
  final String message;

  CategoriesError({required this.message});
}

class CategoryCreating extends CourseState {}

class CategoryCreated extends CourseState {
  final CategoryModel category;

  CategoryCreated({required this.category});
}

class CategoryCreateError extends CourseState {
  final String message;

  CategoryCreateError({required this.message});
}

// Update Category States
class CategoryUpdating extends CourseState {}

class CategoryUpdated extends CourseState {
  final CategoryModel category;

  CategoryUpdated({required this.category});
}

class CategoryUpdateError extends CourseState {
  final String message;

  CategoryUpdateError({required this.message});
}

class CategoryDeleting extends CourseState {}

class CategoryDeleted extends CourseState {
  final int deletedCategoryId;

  CategoryDeleted({required this.deletedCategoryId});
}

class CategoryDeleteError extends CourseState {
  final String message;

  CategoryDeleteError({required this.message});
}

// Attachment Upload States
class AttachmentsUploading extends CourseState {}

class AttachmentsUploaded extends CourseState {
  final List<AttachmentModel> attachments;

  AttachmentsUploaded({required this.attachments});
}

class AttachmentsUploadError extends CourseState {
  final String message;

  AttachmentsUploadError({required this.message});
}

// Fetch Attachments States
class AttachmentsLoading extends CourseState {}

class AttachmentsLoaded extends CourseState {
  final List<AttachmentModel> attachments;

  AttachmentsLoaded({required this.attachments});
}

class AttachmentsError extends CourseState {
  final String message;

  AttachmentsError({required this.message});
}

// Delete Attachment States
class AttachmentDeleting extends CourseState {}

class AttachmentDeleted extends CourseState {}

class AttachmentDeleteError extends CourseState {
  final String message;

  AttachmentDeleteError({required this.message});
}
