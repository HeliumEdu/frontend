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

abstract class ResourceRepository {
  Future<List<ResourceGroupModel>> getResourceGroups({bool forceRefresh = false});

  Future<ResourceGroupModel> createResourceGroup(
    ResourceGroupRequestModel request,
  );

  Future<ResourceGroupModel> updateResourceGroup(
    int id,
    ResourceGroupRequestModel request,
  );

  Future<void> deleteResourceGroup(int id);

  Future<List<ResourceModel>> getResources({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<ResourceModel> getResource(int groupId, int resourceId, {bool forceRefresh = false});

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
