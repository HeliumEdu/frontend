// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/domain/repositories/category_repository.dart';
import 'package:heliumedu/presentation/bloc/categoryBloc/category_event.dart';
import 'package:heliumedu/presentation/bloc/categoryBloc/category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository})
    : super(const CategoryInitial()) {
    on<FetchCategoriesEvent>(_onFetchCategories);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      print('🎯 Fetching categories from repository...');
      final categories = await categoryRepository.getCategories(
        course: event.course,
        title: event.title,
      );
      print(
        '✅ Categories fetched successfully: ${categories.length} categories',
      );
      emit(CategoryLoaded(categories: categories));
    } on ValidationException catch (e) {
      print('❌ Validation error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on NetworkException catch (e) {
      print('❌ Network error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on ServerException catch (e) {
      print('❌ Server error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on UnauthorizedException catch (e) {
      print('❌ Unauthorized error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(CategoryError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(CategoryError(message: 'An unexpected error occurred: $e'));
    }
  }
}
