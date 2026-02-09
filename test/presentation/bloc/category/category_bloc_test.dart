// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/category_request_model.dart';
import 'package:heliumapp/presentation/bloc/category/category_bloc.dart';
import 'package:heliumapp/presentation/bloc/category/category_event.dart';
import 'package:heliumapp/presentation/bloc/category/category_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepository;
  late CategoryBloc categoryBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    categoryBloc = CategoryBloc(categoryRepository: mockCategoryRepository);
  });

  tearDown(() {
    categoryBloc.close();
  });

  group('CategoryBloc', () {
    test('initial state is CategoryInitial with bloc origin', () {
      expect(categoryBloc.state, isA<CategoryInitial>());
    });

    group('FetchCategoriesEvent', () {
      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesFetched] when fetch succeeds',
        build: () {
          when(
            () => mockCategoryRepository.getCategories(
              courseId: any(named: 'courseId'),
              title: any(named: 'title'),
            ),
          ).thenAnswer((_) async => MockModels.createCategories());
          return categoryBloc;
        },
        act: (bloc) =>
            bloc.add(FetchCategoriesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesFetched>().having(
            (s) => s.categories.length,
            'categories length',
            3,
          ),
        ],
        verify: (_) {
          verify(
            () => mockCategoryRepository.getCategories(
              courseId: null,
              title: null,
            ),
          ).called(1);
        },
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesFetched] with courseId filter',
        build: () {
          when(
            () => mockCategoryRepository.getCategories(
              courseId: 5,
              title: null,
            ),
          ).thenAnswer(
            (_) async => MockModels.createCategories(count: 2, courseId: 5),
          );
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          FetchCategoriesEvent(origin: EventOrigin.screen, courseId: 5),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesFetched>().having(
            (s) => s.categories.length,
            'categories length',
            2,
          ),
        ],
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesError] when HeliumException occurs',
        build: () {
          when(
            () => mockCategoryRepository.getCategories(
              courseId: any(named: 'courseId'),
              title: any(named: 'title'),
            ),
          ).thenThrow(ServerException(message: 'Server error'));
          return categoryBloc;
        },
        act: (bloc) =>
            bloc.add(FetchCategoriesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesError] for unexpected errors',
        build: () {
          when(
            () => mockCategoryRepository.getCategories(
              courseId: any(named: 'courseId'),
              title: any(named: 'title'),
            ),
          ).thenThrow(Exception('Unknown error'));
          return categoryBloc;
        },
        act: (bloc) =>
            bloc.add(FetchCategoriesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('CreateCategoryEvent', () {
      const courseGroupId = 1;
      const courseId = 2;
      final request = CategoryRequestModel(
        title: 'New Category',
        color: '#FF5733',
        weight: '25.0',
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoryCreated] when creation succeeds',
        build: () {
          when(
            () => mockCategoryRepository.createCategory(
              courseGroupId,
              courseId,
              any(),
            ),
          ).thenAnswer(
            (_) async => MockModels.createCategory(
              id: 10,
              title: 'New Category',
            ),
          );
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          CreateCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            request: request,
          ),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoryCreated>()
              .having((s) => s.category.id, 'category id', 10)
              .having((s) => s.category.title, 'title', 'New Category'),
        ],
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesError] when creation fails',
        build: () {
          when(
            () => mockCategoryRepository.createCategory(
              courseGroupId,
              courseId,
              any(),
            ),
          ).thenThrow(ValidationException(message: 'Invalid category data'));
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          CreateCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            request: request,
          ),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesError>().having(
            (e) => e.message,
            'message',
            'Invalid category data',
          ),
        ],
      );
    });

    group('UpdateCategoryEvent', () {
      const courseGroupId = 1;
      const courseId = 2;
      const categoryId = 3;
      final request = CategoryRequestModel(
        title: 'Updated Category',
        color: '#00FF00',
        weight: '30.0',
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoryUpdated] when update succeeds',
        build: () {
          when(
            () => mockCategoryRepository.updateCategory(
              courseGroupId,
              courseId,
              categoryId,
              any(),
            ),
          ).thenAnswer(
            (_) async => MockModels.createCategory(
              id: categoryId,
              title: 'Updated Category',
            ),
          );
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            categoryId: categoryId,
            request: request,
          ),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoryUpdated>()
              .having((s) => s.category.id, 'category id', categoryId)
              .having((s) => s.category.title, 'title', 'Updated Category'),
        ],
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesError] when category not found',
        build: () {
          when(
            () => mockCategoryRepository.updateCategory(
              courseGroupId,
              courseId,
              categoryId,
              any(),
            ),
          ).thenThrow(NotFoundException(message: 'Category not found'));
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          UpdateCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            categoryId: categoryId,
            request: request,
          ),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesError>().having(
            (e) => e.message,
            'message',
            'Category not found',
          ),
        ],
      );
    });

    group('DeleteCategoryEvent', () {
      const courseGroupId = 1;
      const courseId = 2;
      const categoryId = 3;

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoryDeleted] when deletion succeeds (not last category)',
        build: () {
          when(
            () => mockCategoryRepository.deleteCategory(
              courseGroupId,
              courseId,
              categoryId,
            ),
          ).thenAnswer((_) async {});
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            categoryId: categoryId,
            isLastCategory: false,
          ),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoryDeleted>().having((s) => s.id, 'id', categoryId),
        ],
        verify: (_) {
          verify(
            () => mockCategoryRepository.deleteCategory(
              courseGroupId,
              courseId,
              categoryId,
            ),
          ).called(1);
        },
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoryDeleted, CategoriesFetched] when deleting last category',
        build: () {
          when(
            () => mockCategoryRepository.deleteCategory(
              courseGroupId,
              courseId,
              categoryId,
            ),
          ).thenAnswer((_) async {});
          when(
            () => mockCategoryRepository.getCategories(courseId: courseId),
          ).thenAnswer(
            (_) async => [MockModels.createCategory(title: 'Uncategorized')],
          );
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            categoryId: categoryId,
            isLastCategory: true,
          ),
        ),
        wait: const Duration(seconds: 3),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoryDeleted>().having((s) => s.id, 'id', categoryId),
          isA<CategoriesFetched>().having(
            (s) => s.categories.first.title,
            'first category title',
            'Uncategorized',
          ),
        ],
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoriesLoading, CategoriesError] when deletion fails',
        build: () {
          when(
            () => mockCategoryRepository.deleteCategory(
              courseGroupId,
              courseId,
              categoryId,
            ),
          ).thenThrow(ServerException(message: 'Cannot delete category'));
          return categoryBloc;
        },
        act: (bloc) => bloc.add(
          DeleteCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: courseGroupId,
            courseId: courseId,
            categoryId: categoryId,
            isLastCategory: false,
          ),
        ),
        expect: () => [
          isA<CategoriesLoading>(),
          isA<CategoriesError>().having(
            (e) => e.message,
            'message',
            'Cannot delete category',
          ),
        ],
      );
    });
  });
}
