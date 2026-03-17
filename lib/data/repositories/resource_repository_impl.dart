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
  Future<ResourceGroupModel> createResourceGroup({
    required ResourceGroupRequestModel request,
  }) async {
    return await remoteDataSource.createResourceGroup(request: request);
  }

  @override
  Future<ResourceGroupModel> updateResourceGroup({
    required int id,
    required ResourceGroupRequestModel request,
  }) async {
    return await remoteDataSource.updateResourceGroup(
      groupId: id,
      request: request,
    );
  }

  @override
  Future<void> deleteResourceGroup({required int id}) async {
    return await remoteDataSource.deleteResourceGroup(groupId: id);
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
  Future<ResourceModel> getResource({
    required int groupId,
    required int resourceId,
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getResourceById(
      groupId: groupId,
      resourceId: resourceId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<ResourceModel> createResource({
    required int groupId,
    required ResourceRequestModel request,
  }) async {
    return await remoteDataSource.createResource(
      groupId: groupId,
      request: request,
    );
  }

  @override
  Future<ResourceModel> updateResource({
    required int groupId,
    required int resourceId,
    required ResourceRequestModel request,
  }) async {
    return await remoteDataSource.updateResource(
      groupId: groupId,
      resourceId: resourceId,
      request: request,
    );
  }

  @override
  Future<void> deleteResource({
    required int groupId,
    required int resourceId,
  }) async {
    return await remoteDataSource.deleteResource(
      groupId: groupId,
      resourceId: resourceId,
    );
  }
}
