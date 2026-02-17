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
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_group_request_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class ResourceRemoteDataSource extends BaseDataSource {
  Future<List<ResourceGroupModel>> getResourceGroups({bool forceRefresh = false});

  Future<ResourceGroupModel> getResourceGroupById(int groupId, {bool forceRefresh = false});

  Future<ResourceGroupModel> createResourceGroup(
    ResourceGroupRequestModel request,
  );

  Future<ResourceGroupModel> updateResourceGroup(
    int groupId,
    ResourceGroupRequestModel request,
  );

  Future<void> deleteResourceGroup(int groupId);

  Future<List<ResourceModel>> getResources({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<ResourceModel> getResourceById(int groupId, int resourceId, {bool forceRefresh = false});

  Future<ResourceModel> createResource(
    int groupId,
    ResourceRequestModel request,
  );

  Future<ResourceModel> updateResource(
    int groupId,
    int resourceId,
    ResourceRequestModel request,
  );

  Future<void> deleteResource(int groupId, int resourceId);
}

class ResourceRemoteDataSourceImpl extends ResourceRemoteDataSource {
  final DioClient dioClient;

  ResourceRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ResourceGroupModel>> getResourceGroups({bool forceRefresh = false}) async {
    try {
      _log.info('Fetching ResourceGroups ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerResourceGroupsListUrl,
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final groups = (response.data as List)
              .map((group) => ResourceGroupModel.fromJson(group))
              .toList();
          _log.info('... fetched ${groups.length} ResourceGroup(s)');
          return groups;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch resource groups',
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
  Future<ResourceGroupModel> getResourceGroupById(int groupId, {bool forceRefresh = false}) async {
    try {
      _log.info('Fetching ResourceGroup $groupId ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerResourceGroupsDetailsUrl(groupId),
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        _log.info('... ResourceGroup $groupId fetched');
        return ResourceGroupModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch resource group',
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
  Future<ResourceGroupModel> createResourceGroup(
    ResourceGroupRequestModel request,
  ) async {
    try {
      _log.info('Creating ResourceGroup ...');

      final response = await dioClient.dio.post(
        ApiUrl.plannerResourceGroupsListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final group = ResourceGroupModel.fromJson(response.data);
        _log.info('... ResourceGroup ${group.id} created');
        await dioClient.cacheService.invalidateAll();
        return group;
      } else {
        throw ServerException(
          message: 'Failed to create resource group',
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
  Future<ResourceGroupModel> updateResourceGroup(
    int groupId,
    ResourceGroupRequestModel request,
  ) async {
    try {
      _log.info('Updating ResourceGroup $groupId ...');

      final response = await dioClient.dio.put(
        ApiUrl.plannerResourceGroupsDetailsUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... ResourceGroup $groupId updated');
        await dioClient.cacheService.invalidateAll();
        return ResourceGroupModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update resource group',
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
  Future<void> deleteResourceGroup(int groupId) async {
    try {
      _log.info('Deleting ResourceGroup $groupId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerResourceGroupsDetailsUrl(groupId),
      );

      if (response.statusCode == 204) {
        _log.info('... ResourceGroup $groupId deleted');
        await dioClient.cacheService.invalidateAll();
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete resource group',
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
  Future<List<ResourceModel>> getResources({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    try {
      final filterInfo = groupId != null ? ' for ResourceGroup $groupId' : '';
      _log.info('Fetching Resources$filterInfo ...');

      // shownOnCalendar requires server-side filtering (hierarchical check on parent groups)
      final Map<String, dynamic> queryParameters = {};
      if (shownOnCalendar != null) {
        queryParameters['shown_on_calendar'] = shownOnCalendar;
      }

      final response = await dioClient.dio.get(
        ApiUrl.plannerResourcesListUrl,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          var resources = (response.data as List)
              .map((resource) => ResourceModel.fromJson(resource))
              .toList();

          // Filter by groupId client-side for cache efficiency
          if (groupId != null) {
            resources = resources.where((m) => m.resourceGroup == groupId).toList();
          }

          _log.info('... fetched ${resources.length} Resource(s)');
          return resources;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch resources',
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
  Future<ResourceModel> getResourceById(int groupId, int resourceId, {bool forceRefresh = false}) async {
    try {
      _log.info('Fetching Resource $resourceId in ResourceGroup $groupId ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerResourceGroupsResourceDetailsUrl(groupId, resourceId),
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        _log.info('... Resource $resourceId fetched');
        return ResourceModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch resource',
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
  Future<ResourceModel> createResource(
    int groupId,
    ResourceRequestModel request,
  ) async {
    try {
      _log.info('Creating Resource in ResourceGroup $groupId ...');

      final response = await dioClient.dio.post(
        ApiUrl.plannerResourceGroupsResourcesListUrl(groupId),
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final resource = ResourceModel.fromJson(response.data);
        _log.info('... Resource ${resource.id} created in ResourceGroup $groupId');
        await dioClient.cacheService.invalidateAll();
        return resource;
      } else {
        throw ServerException(
          message: 'Failed to create resource',
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
  Future<ResourceModel> updateResource(
    int groupId,
    int resourceId,
    ResourceRequestModel request,
  ) async {
    try {
      _log.info('Updating Resource $resourceId in ResourceGroup $groupId ...');
      final response = await dioClient.dio.put(
        ApiUrl.plannerResourceGroupsResourceDetailsUrl(groupId, resourceId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Resource $resourceId updated');
        await dioClient.cacheService.invalidateAll();
        return ResourceModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update resource',
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
  Future<void> deleteResource(int groupId, int resourceId) async {
    try {
      _log.info('Deleting Resource $resourceId in ResourceGroup $groupId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerResourceGroupsResourceDetailsUrl(groupId, resourceId),
      );

      if (response.statusCode == 204) {
        _log.info('... Resource $resourceId deleted');
        await dioClient.cacheService.invalidateAll();
        return;
      } else {
        throw ServerException(
          message: 'Failed to delete resource',
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
