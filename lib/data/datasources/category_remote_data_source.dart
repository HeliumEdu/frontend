// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/api_url.dart';
import 'package:helium_mobile/data/models/planner/category_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories({int? course, String? title});
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final DioClient dioClient;

  CategoryRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CategoryModel>> getCategories({
    int? course,
    String? title,
  }) async {
    try {
      log.info('🎯 Fetching categories...');

      // Build query parameters
      Map<String, dynamic> queryParams = {};
      if (course != null) {
        queryParams['course'] = course;
      }
      if (title != null && title.isNotEmpty) {
        queryParams['title'] = title;
      }

      final response = await dioClient.dio.get(
        NetworkUrl.allCategoriesUrl,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = response.data;
        final categories = categoriesJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        log.info('✅ Fetched ${categories.length} categories');
        return categories;
      } else {
        throw ServerException(
          message: 'Failed to fetch categories',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  HeliumException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData is Map<String, dynamic>) {
          if (statusCode == 400) {
            return ValidationException(
              message: 'Invalid request parameters',
              details: {},
            );
          } else if (statusCode == 401) {
            return UnauthorizedException(
              message: 'Unauthorized access',
              code: '401',
            );
          } else if (statusCode == 500) {
            return ServerException(
              message: 'Server error. Please try again later.',
              code: '500',
            );
          } else {
            return ServerException(
              message:
                  'Server error: ${responseData['detail'] ?? 'Unknown error'}',
              code: statusCode.toString(),
            );
          }
        }

        return ServerException(
          message:
              'Server error: ${error.response?.statusMessage ?? "Unknown error"}',
          code: statusCode.toString(),
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return NetworkException(
            message: 'No internet connection',
            code: 'NO_INTERNET',
          );
        }
        return NetworkException(
          message: 'Network error occurred. Please check your connection.',
          code: 'UNKNOWN',
        );

      default:
        return NetworkException(
          message: 'Network error: ${error.message}',
          code: 'NETWORK_ERROR',
        );
    }
  }
}
