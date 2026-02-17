// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/category_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class CategoryEvent extends BaseEvent {
  CategoryEvent({required super.origin});
}

class FetchCategoriesEvent extends CategoryEvent {
  final int? courseId;
  final String? title;

  FetchCategoriesEvent({required super.origin, this.courseId, this.title});
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

  UpdateCategoryEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.categoryId,
    required this.request,
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
