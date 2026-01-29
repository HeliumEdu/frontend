// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/presentation/bloc/category/category_event.dart';
import 'package:heliumapp/presentation/bloc/category/category_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository})
    : super(CategoryInitial(origin: EventOrigin.bloc)) {
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));
    try {
      final categories = await categoryRepository.getCategories(
        courseId: event.courseId,
        title: event.title,
      );
      emit(CategoriesFetched(origin: event.origin, categories: categories));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));

    try {
      final category = await categoryRepository.createCategory(
        event.courseGroupId,
        event.courseId,
        event.request,
      );
      emit(CategoryCreated(origin: event.origin, category: category));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));

    try {
      final category = await categoryRepository.updateCategory(
        event.courseGroupId,
        event.courseId,
        event.categoryId,
        event.request,
      );
      emit(CategoryUpdated(origin: event.origin, category: category));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));

    try {
      await categoryRepository.deleteCategory(
        event.courseGroupId,
        event.courseId,
        event.categoryId,
      );

      List<CategoryModel> categories = [];
      if (event.isLastCategory) {
        // Wait for the backend to provision "Uncategorized" so it can be emitted
        const int maxRetries = 2;
        int retries = 0;
        while (retries < maxRetries &&
            (categories.isEmpty || categories[0].title != 'Uncategorized')) {
          await Future.delayed(const Duration(seconds: 1));
          retries += 1;

          categories = await categoryRepository.getCategories(
            courseId: event.courseId,
          );
        }
      }

      emit(CategoryDeleted(origin: event.origin, id: event.categoryId));

      if (event.isLastCategory) {
        emit(
          CategoriesFetched(origin: EventOrigin.bloc, categories: categories),
        );
      }
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}
