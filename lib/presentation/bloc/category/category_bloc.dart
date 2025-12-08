// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/presentation/bloc/category/category_event.dart';
import 'package:heliumapp/presentation/bloc/category/category_state.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

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
      log.info('🎯 Fetching categories from repository...');
      final categories = await categoryRepository.getCategories(
        course: event.course,
        title: event.title,
      );
      log.info(
        '✅ Categories fetched successfully: ${categories.length} categories',
      );
      emit(CategoryLoaded(categories: categories));
    } on ValidationException catch (e) {
      log.info('❌ Validation error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on NetworkException catch (e) {
      log.info('❌ Network error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on ServerException catch (e) {
      log.info('❌ Server error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on UnauthorizedException catch (e) {
      log.info('❌ Unauthorized error: ${e.message}');
      emit(CategoryError(message: e.message));
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(CategoryError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(CategoryError(message: 'An unexpected error occurred: $e'));
    }
  }
}
