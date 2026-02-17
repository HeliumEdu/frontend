// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_group_request_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_request_model.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';

class ResourceRepositoryImpl implements ResourceRepository {
  final ResourceRemoteDataSource remoteDataSource;

  ResourceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ResourceGroupModel>> getResourceGroups({bool forceRefresh = false}) async {
    return await remoteDataSource.getResourceGroups(forceRefresh: forceRefresh);
  }

  @override
  Future<ResourceGroupModel> createResourceGroup(
    ResourceGroupRequestModel request,
  ) async {
    return await remoteDataSource.createResourceGroup(request);
  }

  @override
  Future<ResourceGroupModel> updateResourceGroup(
    int groupId,
    ResourceGroupRequestModel request,
  ) async {
    return await remoteDataSource.updateResourceGroup(groupId, request);
  }

  @override
  Future<void> deleteResourceGroup(int groupId) async {
    return await remoteDataSource.deleteResourceGroup(groupId);
  }

  @override
  Future<List<ResourceModel>> getResources({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getResources(
      groupId: groupId,
      shownOnCalendar: shownOnCalendar,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<ResourceModel> getResource(int groupId, int resourceId, {bool forceRefresh = false}) async {
    return await remoteDataSource.getResourceById(groupId, resourceId, forceRefresh: forceRefresh);
  }

  @override
  Future<ResourceModel> createResource(
    int groupId,
    ResourceRequestModel request,
  ) async {
    return await remoteDataSource.createResource(groupId, request);
  }

  @override
  Future<ResourceModel> updateResource(
    int groupId,
    int resourceId,
    ResourceRequestModel request,
  ) async {
    return await remoteDataSource.updateResource(groupId, resourceId, request);
  }

  @override
  Future<void> deleteResource(int groupId, int resourceId) async {
    return await remoteDataSource.deleteResource(groupId, resourceId);
  }
}
