// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/material_group_response_model.dart';
import 'package:heliumedu/data/models/planner/material_model.dart';

abstract class MaterialState {}

class MaterialInitial extends MaterialState {}

// Fetch all material groups
class MaterialGroupsLoading extends MaterialState {}

class MaterialGroupsLoaded extends MaterialState {
  final List<MaterialGroupResponseModel> materialGroups;

  MaterialGroupsLoaded({required this.materialGroups});
}

class MaterialGroupsError extends MaterialState {
  final String message;

  MaterialGroupsError({required this.message});
}

// Fetch material group by ID
class MaterialGroupDetailLoading extends MaterialState {}

class MaterialGroupDetailLoaded extends MaterialState {
  final MaterialGroupResponseModel materialGroup;

  MaterialGroupDetailLoaded({required this.materialGroup});
}

class MaterialGroupDetailError extends MaterialState {
  final String message;

  MaterialGroupDetailError({required this.message});
}

// Create material group
class MaterialGroupCreating extends MaterialState {}

class MaterialGroupCreated extends MaterialState {
  final MaterialGroupResponseModel materialGroup;

  MaterialGroupCreated({required this.materialGroup});
}

class MaterialGroupCreateError extends MaterialState {
  final String message;

  MaterialGroupCreateError({required this.message});
}

// Update material group
class MaterialGroupUpdating extends MaterialState {}

class MaterialGroupUpdated extends MaterialState {
  final MaterialGroupResponseModel materialGroup;

  MaterialGroupUpdated({required this.materialGroup});
}

class MaterialGroupUpdateError extends MaterialState {
  final String message;

  MaterialGroupUpdateError({required this.message});
}

// Delete material group
class MaterialGroupDeleting extends MaterialState {}

class MaterialGroupDeleted extends MaterialState {}

class MaterialGroupDeleteError extends MaterialState {
  final String message;

  MaterialGroupDeleteError({required this.message});
}

// Fetch materials
class MaterialsLoading extends MaterialState {}

class MaterialsLoaded extends MaterialState {
  final List<MaterialModel> materials;

  MaterialsLoaded({required this.materials});
}

class MaterialsError extends MaterialState {
  final String message;

  MaterialsError({required this.message});
}

// Create material
class MaterialCreating extends MaterialState {}

class MaterialCreated extends MaterialState {
  final MaterialModel material;

  MaterialCreated({required this.material});
}

class MaterialCreateError extends MaterialState {
  final String message;

  MaterialCreateError({required this.message});
}

// Update material
class MaterialUpdating extends MaterialState {}

class MaterialUpdated extends MaterialState {
  final MaterialModel material;

  MaterialUpdated({required this.material});
}

class MaterialUpdateError extends MaterialState {
  final String message;

  MaterialUpdateError({required this.message});
}

// Delete material
class MaterialDeleting extends MaterialState {}

class MaterialDeleted extends MaterialState {}

class MaterialDeleteError extends MaterialState {
  final String message;

  MaterialDeleteError({required this.message});
}
