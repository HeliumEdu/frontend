// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class CategoryState extends BaseState {
  CategoryState({required super.origin, super.message});
}

abstract class CategoryEntityState extends CategoryState {
  final CategoryModel category;

  CategoryEntityState({required super.origin, required this.category});
}

class CategoryInitial extends CategoryState {
  CategoryInitial({required super.origin});
}

class CategoriesLoading extends CategoryState {
  CategoriesLoading({required super.origin});
}

class CategoriesError extends CategoryState {
  CategoriesError({required super.origin, required super.message});
}

class CategoriesFetched extends CategoryState {
  final List<CategoryModel> categories;

  CategoriesFetched({required super.origin, required this.categories});
}

class CategoryCreated extends CategoryEntityState {
  CategoryCreated({required super.origin, required super.category});
}

class CategoryUpdated extends CategoryEntityState {
  CategoryUpdated({required super.origin, required super.category});
}

class CategoryDeleted extends CategoryState {
  final int id;

  CategoryDeleted({required super.origin, required this.id});
}
