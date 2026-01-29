// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/material_group_model.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_state.dart';

abstract class MaterialState extends BaseState {
  MaterialState({required super.origin, super.message});
}

abstract class MaterialGroupEntityState extends MaterialState {
  final MaterialGroupModel materialGroup;

  MaterialGroupEntityState({
    required super.origin,
    required this.materialGroup,
  });
}

abstract class MaterialEntityState extends MaterialState {
  final MaterialModel material;

  MaterialEntityState({
    required super.origin,
    required this.material,
    super.message,
  });
}

class MaterialsInitial extends MaterialState {
  MaterialsInitial({required super.origin});
}

class MaterialsLoading extends MaterialState {
  MaterialsLoading({required super.origin});
}

class MaterialsError extends MaterialState {
  MaterialsError({required super.origin, required super.message});
}

class MaterialsScreenDataFetched extends MaterialState {
  final List<MaterialGroupModel> materialGroups;
  final List<MaterialModel> materials;
  final List<CourseModel> courses;

  MaterialsScreenDataFetched({
    required super.origin,
    super.message,
    required this.materialGroups,
    required this.materials,
    required this.courses,
  });
}

class MaterialScreenDataFetched extends MaterialState {
  final MaterialModel? material;
  final List<CourseModel> courses;

  MaterialScreenDataFetched({
    required super.origin,
    required this.material,
    required this.courses,
  });
}

class MaterialsFetched extends MaterialState {
  final List<MaterialModel> materials;

  MaterialsFetched({
    required super.origin,
    super.message,
    required this.materials,
  });
}

class MaterialFetched extends MaterialEntityState {
  MaterialFetched({required super.origin, required super.material});
}

class MaterialGroupCreated extends MaterialGroupEntityState {
  MaterialGroupCreated({required super.origin, required super.materialGroup});
}

class MaterialGroupUpdated extends MaterialGroupEntityState {
  MaterialGroupUpdated({required super.origin, required super.materialGroup});
}

class MaterialGroupDeleted extends MaterialState {
  final int id;

  MaterialGroupDeleted({required super.origin, required this.id});
}

class MaterialCreated extends MaterialEntityState {
  MaterialCreated({required super.origin, required super.material});
}

class MaterialUpdated extends MaterialEntityState {
  MaterialUpdated({required super.origin, required super.material});
}

class MaterialDeleted extends MaterialState {
  final int id;

  MaterialDeleted({required super.origin, required this.id});
}
