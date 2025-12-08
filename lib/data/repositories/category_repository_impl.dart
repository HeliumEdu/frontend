// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CategoryModel>> getCategories({
    int? course,
    String? title,
  }) async {
    return await remoteDataSource.getCategories(course: course, title: title);
  }
}
