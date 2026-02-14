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
import 'package:heliumapp/data/sources/material_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/material_repository.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  final MaterialRemoteDataSource remoteDataSource;

  MaterialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MaterialGroupModel>> getMaterialGroups({bool forceRefresh = false}) async {
    return await remoteDataSource.getMaterialGroups(forceRefresh: forceRefresh);
  }

  @override
  Future<MaterialGroupModel> createMaterialGroup(
    MaterialGroupRequestModel request,
  ) async {
    return await remoteDataSource.createMaterialGroup(request);
  }

  @override
  Future<MaterialGroupModel> updateMaterialGroup(
    int groupId,
    MaterialGroupRequestModel request,
  ) async {
    return await remoteDataSource.updateMaterialGroup(groupId, request);
  }

  @override
  Future<void> deleteMaterialGroup(int groupId) async {
    return await remoteDataSource.deleteMaterialGroup(groupId);
  }

  @override
  Future<List<MaterialModel>> getMaterials({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getMaterials(
      groupId: groupId,
      shownOnCalendar: shownOnCalendar,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<MaterialModel> getMaterial(int groupId, int materialId, {bool forceRefresh = false}) async {
    return await remoteDataSource.getMaterialById(groupId, materialId, forceRefresh: forceRefresh);
  }

  @override
  Future<MaterialModel> createMaterial(
    int groupId,
    MaterialRequestModel request,
  ) async {
    return await remoteDataSource.createMaterial(groupId, request);
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
