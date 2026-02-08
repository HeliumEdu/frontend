// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CategoryModel>> getCategories({
    int? courseId,
    String? title,
    bool? shownOnCalendar,
  }) async {
    return await remoteDataSource.getCategories(
      courseId: courseId,
      title: title,
      shownOnCalendar: shownOnCalendar
    );
  }

  @override
  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  ) async {
    return await remoteDataSource.createCategory(groupId, courseId, request);
  }

  @override
  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  ) async {
    return await remoteDataSource.updateCategory(
      groupId,
      courseId,
      categoryId,
      request,
    );
  }

  @override
  Future<void> deleteCategory(int groupId, int courseId, int categoryId) async {
    return await remoteDataSource.deleteCategory(groupId, courseId, categoryId);
  }
}
