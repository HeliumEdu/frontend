// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/material_group_model.dart';
import 'package:heliumapp/data/models/planner/request/material_group_request_model.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/data/models/planner/request/material_request_model.dart';

abstract class MaterialRepository {
  Future<List<MaterialGroupModel>> getMaterialGroups({bool forceRefresh = false});

  Future<MaterialGroupModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  );

  Future<MaterialGroupModel> updateMaterialGroup(
    int id,
    MaterialGroupRequestModel request,
  );

  Future<void> deleteMaterialGroup(int id);

  Future<List<MaterialModel>> getMaterials({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<MaterialModel> getMaterial(int groupId, int materialId, {bool forceRefresh = false});

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
