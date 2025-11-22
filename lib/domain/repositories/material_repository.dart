// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/models/planner/material_group_request_model.dart';
import 'package:helium_mobile/data/models/planner/material_group_response_model.dart';
import 'package:helium_mobile/data/models/planner/material_model.dart';
import 'package:helium_mobile/data/models/planner/material_request_model.dart';

abstract class MaterialRepository {
  Future<List<MaterialGroupResponseModel>> getMaterialGroups();

  Future<MaterialGroupResponseModel> getMaterialGroupById(int groupId);

  Future<MaterialGroupResponseModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  );

  Future<MaterialGroupResponseModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  );

  Future<void> deleteMaterialGroup(int groupId);

  Future<List<MaterialModel>> getAllMaterials();

  Future<List<MaterialModel>> getMaterials(int groupId);

  Future<MaterialModel> getMaterialById(int groupId, int materialId);

  Future<MaterialModel> createMaterial(MaterialRequestModel request);

  Future<MaterialModel> updateMaterial(
    int groupId,
    int materialId,
    MaterialRequestModel request,
  );

  Future<void> deleteMaterial(int groupId, int materialId);
}
