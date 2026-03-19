// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class ResourceState extends BaseState {
  ResourceState({required super.origin, super.message});
}

abstract class ResourceGroupEntityState extends ResourceState {
  final ResourceGroupModel resourceGroup;

  ResourceGroupEntityState({
    required super.origin,
    required this.resourceGroup,
  });
}

abstract class ResourceEntityState extends ResourceState {
  final ResourceModel resource;

  ResourceEntityState({
    required super.origin,
    required this.resource,
    super.message,
  });
}

class ResourcesInitial extends ResourceState {
  ResourcesInitial({required super.origin});
}

class ResourcesLoading extends ResourceState {
  ResourcesLoading({required super.origin});
}

class ResourcesError extends ResourceState {
  ResourcesError({required super.origin, required super.message});
}

class ResourcesScreenDataFetched extends ResourceState {
  final List<ResourceGroupModel> resourceGroups;
  final List<ResourceModel> resources;
  final List<CourseModel> courses;
  final List<NoteModel> notes;

  ResourcesScreenDataFetched({
    required super.origin,
    super.message,
    required this.resourceGroups,
    required this.resources,
    required this.courses,
    required this.notes,
  });
}

class ResourceScreenDataFetched extends ResourceState {
  final ResourceModel? resource;
  final List<CourseModel> courses;
  final NoteModel? linkedNote;

  ResourceScreenDataFetched({
    required super.origin,
    required this.resource,
    required this.courses,
    this.linkedNote,
  });
}

class ResourcesFetched extends ResourceState {
  final List<ResourceModel> resources;

  ResourcesFetched({
    required super.origin,
    super.message,
    required this.resources,
  });
}

class ResourceFetched extends ResourceEntityState {
  ResourceFetched({required super.origin, required super.resource});
}

class ResourceGroupCreated extends ResourceGroupEntityState {
  ResourceGroupCreated({required super.origin, required super.resourceGroup});
}

class ResourceGroupUpdated extends ResourceGroupEntityState {
  ResourceGroupUpdated({required super.origin, required super.resourceGroup});
}

class ResourceGroupDeleted extends ResourceState {
  final int id;

  ResourceGroupDeleted({required super.origin, required this.id});
}

class ResourceCreated extends ResourceEntityState {
  final bool redirectToNotebook;

  ResourceCreated({
    required super.origin,
    required super.resource,
    this.redirectToNotebook = false,
  });
}

class ResourceUpdated extends ResourceEntityState {
  final bool redirectToNotebook;

  ResourceUpdated({
    required super.origin,
    required super.resource,
    this.redirectToNotebook = false,
  });
}

class ResourceDeleted extends ResourceState {
  final int id;

  ResourceDeleted({required super.origin, required this.id});
}
