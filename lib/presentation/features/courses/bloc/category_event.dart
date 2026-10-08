import 'package:heliumapp/data/models/planner/request/category_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class CategoryEvent extends BaseEvent {
  CategoryEvent({required super.origin});
}

class FetchCategoriesEvent extends CategoryEvent {
  final int? courseId;
  final String? title;
  final bool forceRefresh;
  final bool passive;

  FetchCategoriesEvent({
    required super.origin,
    this.courseId,
    this.title,
    this.forceRefresh = false,
    this.passive = false,
  });
}

class CreateCategoryEvent extends CategoryEvent {
  final int courseGroupId;
  final int courseId;
  final CategoryRequestModel request;

  CreateCategoryEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
  });
}

class UpdateCategoryEvent extends CategoryEvent {
  final int courseGroupId;
  final int courseId;
  final int categoryId;
  final CategoryRequestModel request;
  /// The item's version as last read; when set, a stale save emits a
  /// conflict state instead of overwriting.
  final String? version;

  UpdateCategoryEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.categoryId,
    required this.request,
    this.version,
  });
}

class DeleteCategoryEvent extends CategoryEvent {
  final int courseGroupId;
  final int courseId;
  final int categoryId;
  final bool isLastCategory;

  DeleteCategoryEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.categoryId,
    required this.isLastCategory,
  });
}

class ResetCategoriesEvent extends CategoryEvent {
  ResetCategoriesEvent() : super(origin: EventOrigin.bloc);
}
