import 'package:helium_student_flutter/data/models/planner/material_group_request_model.dart';
import 'package:helium_student_flutter/data/models/planner/material_group_response_model.dart';
import 'package:helium_student_flutter/data/models/planner/material_model.dart';
import 'package:helium_student_flutter/data/models/planner/material_request_model.dart';

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

  // Materials
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
