// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/datasources/material_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/material_group_request_model.dart';
import 'package:heliumedu/data/models/planner/material_group_response_model.dart';
import 'package:heliumedu/data/models/planner/material_model.dart';
import 'package:heliumedu/data/models/planner/material_request_model.dart';
import 'package:heliumedu/domain/repositories/material_repository.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  final MaterialRemoteDataSource remoteDataSource;

  MaterialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MaterialGroupResponseModel>> getMaterialGroups() async {
    return await remoteDataSource.getMaterialGroups();
  }

  @override
  Future<MaterialGroupResponseModel> getMaterialGroupById(int groupId) async {
    return await remoteDataSource.getMaterialGroupById(groupId);
  }

  @override
  Future<MaterialGroupResponseModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  ) async {
    return await remoteDataSource.createMaterialGroup(request);
  }

  @override
  Future<MaterialGroupResponseModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  ) async {
    return await remoteDataSource.updateMaterialGroup(groupId, request);
  }

  @override
  Future<void> deleteMaterialGroup(int groupId) async {
    return await remoteDataSource.deleteMaterialGroup(groupId);
  }

  // Materials
  @override
  Future<List<MaterialModel>> getAllMaterials() async {
    return await remoteDataSource.getAllMaterials();
  }

  @override
  Future<List<MaterialModel>> getMaterials(int groupId) async {
    return await remoteDataSource.getMaterials(groupId);
  }

  @override
  Future<MaterialModel> getMaterialById(int groupId, int materialId) async {
    return await remoteDataSource.getMaterialById(groupId, materialId);
  }

  @override
  Future<MaterialModel> createMaterial(MaterialRequestModel request) async {
    return await remoteDataSource.createMaterial(request);
  }

  @override
  Future<MaterialModel> updateMaterial(
    int groupId,
    int materialId,
    MaterialRequestModel request,
  ) async {
    return await remoteDataSource.updateMaterial(groupId, materialId, request);
  }

  @override
  Future<void> deleteMaterial(int groupId, int materialId) async {
    return await remoteDataSource.deleteMaterial(groupId, materialId);
  }
}
