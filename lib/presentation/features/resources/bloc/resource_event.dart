// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/resource_group_request_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class ResourceEvent extends BaseEvent {
  ResourceEvent({required super.origin});
}

class FetchResourcesScreenDataEvent extends ResourceEvent {
  FetchResourcesScreenDataEvent({required super.origin});
}

class FetchResourceScreenDataEvent extends ResourceEvent {
  final int resourceGroupId;
  final int? resourceId;

  FetchResourceScreenDataEvent({
    required super.origin,
    required this.resourceGroupId,
    this.resourceId,
  });
}

class FetchResourcesEvent extends ResourceEvent {
  final int? resourceGroupId;
  final bool? shownOnCalendar;

  FetchResourcesEvent({
    required super.origin,
    this.resourceGroupId,
    this.shownOnCalendar,
  });
}

class FetchResourceEvent extends ResourceEvent {
  final int resourceGroupId;
  final int resourceId;

  FetchResourceEvent({
    required super.origin,
    required this.resourceGroupId,
    required this.resourceId,
  });
}

class CreateResourceGroupEvent extends ResourceEvent {
  final ResourceGroupRequestModel request;

  CreateResourceGroupEvent({required super.origin, required this.request});
}

class UpdateResourceGroupEvent extends ResourceEvent {
  final int resourceGroupId;
  final ResourceGroupRequestModel request;

  UpdateResourceGroupEvent({
    required super.origin,
    required this.resourceGroupId,
    required this.request,
  });
}

class DeleteResourceGroupEvent extends ResourceEvent {
  final int resourceGroupId;

  DeleteResourceGroupEvent({
    required super.origin,
    required this.resourceGroupId,
  });
}

class CreateResourceEvent extends ResourceEvent {
  final int resourceGroupId;
  final ResourceRequestModel request;

  CreateResourceEvent({
    required super.origin,
    required this.resourceGroupId,
    required this.request,
  });
}

class UpdateResourceEvent extends ResourceEvent {
  final int resourceGroupId;
  final int resourceId;
  final ResourceRequestModel request;

  UpdateResourceEvent({
    required super.origin,
    required this.resourceGroupId,
    required this.resourceId,
    required this.request,
  });
}

class DeleteResourceEvent extends ResourceEvent {
  final int resourceGroupId;
  final int resourceId;

  DeleteResourceEvent({
    required super.origin,
    required this.resourceGroupId,
    required this.resourceId,
  });
}
