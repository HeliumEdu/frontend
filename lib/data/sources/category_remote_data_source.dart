// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class CategoryRemoteDataSource extends BaseDataSource {
  Future<List<CategoryModel>> getCategories({
    int? courseId,
    String? title,
    bool? shownOnCalendar,
  });

  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  );

  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  );

  Future<void> deleteCategory(int groupId, int courseId, int categoryId);
}

class CategoryRemoteDataSourceImpl extends CategoryRemoteDataSource {
  final DioClient dioClient;

  CategoryRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CategoryModel>> getCategories({
    int? courseId,
    String? title,
    bool? shownOnCalendar,
  }) async {
    try {
      final filterInfo = courseId != null ? ' for Course $courseId' : '';
      _log.info('Fetching Categories$filterInfo ...');

      final Map<String, dynamic> queryParameters = {};
      if (courseId != null) queryParameters['course'] = courseId;
      if (title?.isNotEmpty ?? false) queryParameters['title'] = title;
      if (shownOnCalendar != null) queryParameters['shown_on_calendar'] = shownOnCalendar;

      final response = await dioClient.dio.get(
        ApiUrl.plannerCategoriesListUrl,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = response.data;
        final categories = categoriesJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        _log.info('... fetched ${categories.length} Category(ies)');
        return categories;
      } else {
        throw ServerException(
          message: 'Failed to fetch categories',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  ) async {
    try {
      _log.info('Creating Category for Course $courseId ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerCourseGroupsCoursesCategoriesListUrl(groupId, courseId),
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final category = CategoryModel.fromJson(response.data);
        _log.info('... Category ${category.id} created for Course $courseId');
        return category;
      } else {
        throw ServerException(
          message: 'Failed to create category',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  ) async {
    try {
      _log.info('Updating Category $categoryId for Course $courseId ...');

      final response = await dioClient.dio.put(
        ApiUrl.plannerCourseGroupsCoursesCategoriesDetailsUrl(
          groupId,
          courseId,
          categoryId,
        ),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Category $categoryId updated');
        return CategoryModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update category',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteCategory(int groupId, int courseId, int categoryId) async {
    try {
      _log.info('Deleting Category $categoryId for Course $courseId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerCourseGroupsCoursesCategoriesDetailsUrl(
          groupId,
          courseId,
          categoryId,
        ),
      );

      if (response.statusCode == 204) {
        _log.info('... Category $categoryId deleted');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete category',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }
}
