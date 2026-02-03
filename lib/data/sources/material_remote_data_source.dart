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
import 'package:heliumapp/data/models/planner/material_group_model.dart';
import 'package:heliumapp/data/models/planner/material_group_request_model.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/data/models/planner/material_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class MaterialRemoteDataSource extends BaseDataSource {
  Future<List<MaterialGroupModel>> getMaterialGroups();

  Future<MaterialGroupModel> getMaterialGroupById(int groupId);

  Future<MaterialGroupModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  );

  Future<MaterialGroupModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  );

  Future<void> deleteMaterialGroup(int groupId);

  Future<List<MaterialModel>> getMaterials({
    int? groupId,
    bool? shownOnCalendar,
  });

  Future<MaterialModel> getMaterialById(int groupId, int materialId);

  Future<MaterialModel> createMaterial(
    int groupId,
    MaterialRequestModel request,
  );

  Future<MaterialModel> updateMaterial(
    int groupId,
    int materialId,
    MaterialRequestModel request,
  );

  Future<void> deleteMaterial(int groupId, int materialId);
}

class MaterialRemoteDataSourceImpl extends MaterialRemoteDataSource {
  final DioClient dioClient;

  MaterialRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<MaterialGroupModel>> getMaterialGroups() async {
    try {
      _log.info('Fetching MaterialGroups ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerMaterialGroupsListUrl,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final groups = (response.data as List)
              .map((group) => MaterialGroupModel.fromJson(group))
              .toList();
          _log.info('... fetched ${groups.length} MaterialGroup(s)');
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
  Future<MaterialGroupModel> getMaterialGroupById(int groupId) async {
    try {
      _log.info('Fetching MaterialGroup $groupId ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerMaterialGroupsDetailsUrl(groupId),
      );

      if (response.statusCode == 200) {
        _log.info('... MaterialGroup $groupId fetched');
        return MaterialGroupModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch material group',
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
  Future<MaterialGroupModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  ) async {
    try {
      _log.info('Creating MaterialGroup ...');

      final response = await dioClient.dio.post(
        ApiUrl.plannerMaterialGroupsListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final group = MaterialGroupModel.fromJson(response.data);
        _log.info('... MaterialGroup ${group.id} created');
        return group;
      } else {
        throw ServerException(
          message: 'Failed to create material group',
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
  Future<MaterialGroupModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  ) async {
    try {
      _log.info('Updating MaterialGroup $groupId ...');

      final response = await dioClient.dio.put(
        ApiUrl.plannerMaterialGroupsDetailsUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... MaterialGroup $groupId updated');
        return MaterialGroupModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update material group',
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
  Future<void> deleteMaterialGroup(int groupId) async {
    try {
      _log.info('Deleting MaterialGroup $groupId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerMaterialGroupsDetailsUrl(groupId),
      );

      if (response.statusCode == 204) {
        _log.info('... MaterialGroup $groupId deleted');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete material group',
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
  Future<List<MaterialModel>> getMaterials({
    int? groupId,
    bool? shownOnCalendar,
  }) async {
    try {
      final filterInfo = groupId != null ? ' for MaterialGroup $groupId' : '';
      _log.info('Fetching Materials$filterInfo ...');

      final Map<String, dynamic> queryParameters = {};
      if (groupId != null) {
        queryParameters['material_group'] = groupId;
      }
      if (shownOnCalendar != null) {
        queryParameters['shown_on_calendar'] = shownOnCalendar;
      }

      final response = await dioClient.dio.get(
        ApiUrl.plannerMaterialsListUrl,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final materials = (response.data as List)
              .map((material) => MaterialModel.fromJson(material))
              .toList();
          _log.info('... fetched ${materials.length} Material(s)');
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
  Future<MaterialModel> getMaterialById(int groupId, int materialId) async {
    try {
      _log.info('Fetching Material $materialId in MaterialGroup $groupId ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerMaterialGroupsMaterialDetailsUrl(groupId, materialId),
      );

      if (response.statusCode == 200) {
        _log.info('... Material $materialId fetched');
        return MaterialModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch material',
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
  Future<MaterialModel> createMaterial(
    int groupId,
    MaterialRequestModel request,
  ) async {
    try {
      _log.info('Creating Material in MaterialGroup $groupId ...');

      final response = await dioClient.dio.post(
        ApiUrl.plannerMaterialGroupsMaterialsListUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final material = MaterialModel.fromJson(response.data);
        _log.info('... Material ${material.id} created in MaterialGroup $groupId');
        return material;
      } else {
        throw ServerException(
          message: 'Failed to create material',
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
  Future<MaterialModel> updateMaterial(
    int groupId,
    int materialId,
    MaterialRequestModel request,
  ) async {
    try {
      _log.info('Updating Material $materialId in MaterialGroup $groupId ...');
      final response = await dioClient.dio.put(
        ApiUrl.plannerMaterialGroupsMaterialDetailsUrl(groupId, materialId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Material $materialId updated');
        return MaterialModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update material',
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
  Future<void> deleteMaterial(int groupId, int materialId) async {
    try {
      _log.info('Deleting Material $materialId in MaterialGroup $groupId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerMaterialGroupsMaterialDetailsUrl(groupId, materialId),
      );

      if (response.statusCode == 204) {
        _log.info('... Material $materialId deleted');
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete material',
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
