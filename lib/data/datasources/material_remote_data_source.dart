import 'package:dio/dio.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/core/network_urls.dart';
import 'package:heliumedu/data/models/planner/material_group_request_model.dart';
import 'package:heliumedu/data/models/planner/material_group_response_model.dart';
import 'package:heliumedu/data/models/planner/material_model.dart';
import 'package:heliumedu/data/models/planner/material_request_model.dart';

abstract class MaterialRemoteDataSource {
  Future<List<MaterialGroupResponseModel>> getMaterialGroups();
  Future<MaterialGroupResponseModel> getMaterialGroupById(int groupId);
  Future<MaterialGroupResponseModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  );
  Future<MaterialGroupResponseModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  );
  Future<void> deleteMaterialGroup(int groupId);

  // Materials
  Future<List<MaterialModel>> getAllMaterials();
  Future<List<MaterialModel>> getMaterials(int groupId);
  Future<MaterialModel> getMaterialById(int groupId, int materialId);
  Future<MaterialModel> createMaterial(MaterialRequestModel request);
  Future<MaterialModel> updateMaterial(
    int groupId,
    int materialId,
    MaterialRequestModel request,
  );
  Future<void> deleteMaterial(int groupId, int materialId);
}

class MaterialRemoteDataSourceImpl implements MaterialRemoteDataSource {
  final DioClient dioClient;

  MaterialRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<MaterialGroupResponseModel>> getMaterialGroups() async {
    try {
      print('📚 Fetching material groups...');
      final response = await dioClient.dio.get(NetworkUrl.materialGroupsUrl);

      if (response.statusCode == 200) {
        if (response.data is List) {
          final groups = (response.data as List)
              .map((group) => MaterialGroupResponseModel.fromJson(group))
              .toList();
          print('✅ Fetched ${groups.length} material group(s)');
          return groups;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch material groups',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<MaterialGroupResponseModel> getMaterialGroupById(int groupId) async {
    try {
      print('📖 Fetching material group: $groupId');
      final response = await dioClient.dio.get(
        NetworkUrl.materialGroupByIdUrl(groupId),
      );

      if (response.statusCode == 200) {
        print('✅ Material group fetched successfully!');
        return MaterialGroupResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch material group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<MaterialGroupResponseModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  ) async {
    try {
      print('➕ Creating material group...');
      print('  Title: ${request.title}');
      print('  Show on calendar: ${request.shownOnCalendar}');

      final response = await dioClient.dio.post(
        NetworkUrl.materialGroupsUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Material group created successfully!');
        return MaterialGroupResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create material group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<MaterialGroupResponseModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  ) async {
    try {
      print('🔄 Updating material group: $groupId');
      print('  Title: ${request.title}');
      print('  Show on calendar: ${request.shownOnCalendar}');

      final response = await dioClient.dio.put(
        NetworkUrl.materialGroupByIdUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Material group updated successfully!');
        return MaterialGroupResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update material group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteMaterialGroup(int groupId) async {
    try {
      print('🗑️ Deleting material group: $groupId');
      final response = await dioClient.dio.delete(
        NetworkUrl.materialGroupByIdUrl(groupId),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        print('✅ Material group deleted successfully!');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete material group',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  // Materials Methods
  @override
  Future<List<MaterialModel>> getMaterials(int groupId) async {
    try {
      print('📚 Fetching materials for group: $groupId');
      final response = await dioClient.dio.get(
        NetworkUrl.materialsUrl(groupId),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final materials = (response.data as List)
              .map((material) => MaterialModel.fromJson(material))
              .toList();
          print('✅ Fetched ${materials.length} material(s)');
          return materials;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch materials',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<MaterialModel>> getAllMaterials() async {
    try {
      print('📚 Fetching all materials...');
      final response = await dioClient.dio.get(NetworkUrl.allMaterialsUrl);

      if (response.statusCode == 200) {
        if (response.data is List) {
          final materials = (response.data as List)
              .map((material) => MaterialModel.fromJson(material))
              .toList();
          print('✅ Fetched ${materials.length} material(s)');
          return materials;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch materials',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<MaterialModel> getMaterialById(int groupId, int materialId) async {
    try {
      print('📖 Fetching material: $materialId from group: $groupId');
      final response = await dioClient.dio.get(
        NetworkUrl.materialByIdUrl(groupId, materialId),
      );

      if (response.statusCode == 200) {
        print('✅ Material fetched successfully!');
        return MaterialModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch material',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<MaterialModel> createMaterial(MaterialRequestModel request) async {
    try {
      print('➕ Creating material...');
      print('  Title: ${request.title}');
      print('  Group ID: ${request.materialGroup}');

      final response = await dioClient.dio.post(
        NetworkUrl.materialsUrl(request.materialGroup),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Material created successfully!');
        return MaterialModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create material',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<MaterialModel> updateMaterial(
    int groupId,
    int materialId,
    MaterialRequestModel request,
  ) async {
    try {
      print('🔄 Updating material: $materialId');
      final response = await dioClient.dio.put(
        NetworkUrl.materialByIdUrl(groupId, materialId),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Material updated successfully!');
        return MaterialModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update material',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteMaterial(int groupId, int materialId) async {
    try {
      print('🗑️ Deleting material: $materialId');
      final response = await dioClient.dio.delete(
        NetworkUrl.materialByIdUrl(groupId, materialId),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        print('✅ Material deleted successfully!');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete material',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  AppException _handleDioError(DioException error) {
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

        if (statusCode == 401) {
          return UnauthorizedException(
            message: 'Unauthorized. Please login again.',
            code: '401',
          );
        } else if (statusCode == 400) {
          String errorMessage = 'Validation error occurred.';

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                final errors = <String>[];
                responseData.forEach((key, value) {
                  if (value is List) {
                    for (var msg in value) {
                      errors.add('$key: $msg');
                    }
                  } else {
                    errors.add('$key: $value');
                  }
                });
                if (errors.isNotEmpty) {
                  errorMessage = errors.join('\n');
                }
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (e) {
              errorMessage = 'Validation error: ${responseData.toString()}';
            }
          }

          return ValidationException(
            message: errorMessage,
            code: '400',
            details: responseData,
          );
        } else if (statusCode == 500) {
          return ServerException(
            message: 'Server error. Please try again later.',
            code: '500',
          );
        } else {
          String errorMessage =
              error.response?.statusMessage ?? 'Unknown error';

          if (responseData != null) {
            try {
              if (responseData is Map<String, dynamic>) {
                if (responseData.containsKey('message')) {
                  errorMessage = responseData['message'].toString();
                } else if (responseData.containsKey('error')) {
                  errorMessage = responseData['error'].toString();
                } else if (responseData.containsKey('detail')) {
                  errorMessage = responseData['detail'].toString();
                } else {
                  errorMessage = responseData.toString();
                }
              } else if (responseData is String) {
                errorMessage = responseData;
              }
            } catch (e) {
              errorMessage =
                  'Server error: ${error.response?.statusMessage ?? "Unknown error"}';
            }
          }

          return ServerException(
            message: errorMessage,
            code: statusCode.toString(),
            details: responseData,
          );
        }

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
