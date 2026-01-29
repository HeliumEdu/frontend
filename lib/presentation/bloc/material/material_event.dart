// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/material_group_request_model.dart';
import 'package:heliumapp/data/models/planner/material_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';

abstract class MaterialEvent extends BaseEvent {
  MaterialEvent({required super.origin});
}

class FetchMaterialsScreenDataEvent extends MaterialEvent {
  FetchMaterialsScreenDataEvent({required super.origin});
}

class FetchMaterialScreenDataEvent extends MaterialEvent {
  final int materialGroupId;
  final int? materialId;

  FetchMaterialScreenDataEvent({
    required super.origin,
    required this.materialGroupId,
    this.materialId,
  });
}

class FetchMaterialsEvent extends MaterialEvent {
  final int? materialGroupId;
  final bool? shownOnCalendar;

  FetchMaterialsEvent({
    required super.origin,
    this.materialGroupId,
    this.shownOnCalendar,
  });
}

class FetchMaterialEvent extends MaterialEvent {
  final int materialGroupId;
  final int materialId;

  FetchMaterialEvent({
    required super.origin,
    required this.materialGroupId,
    required this.materialId,
  });
}

class CreateMaterialGroupEvent extends MaterialEvent {
  final MaterialGroupRequestModel request;

  CreateMaterialGroupEvent({required super.origin, required this.request});
}

class UpdateMaterialGroupEvent extends MaterialEvent {
  final int materialGroupId;
  final MaterialGroupRequestModel request;

  UpdateMaterialGroupEvent({
    required super.origin,
    required this.materialGroupId,
    required this.request,
  });
}

class DeleteMaterialGroupEvent extends MaterialEvent {
  final int materialGroupId;

  DeleteMaterialGroupEvent({
    required super.origin,
    required this.materialGroupId,
  });
}

class CreateMaterialEvent extends MaterialEvent {
  final int materialGroupId;
  final MaterialRequestModel request;

  CreateMaterialEvent({
    required super.origin,
    required this.materialGroupId,
    required this.request,
  });
}

class UpdateMaterialEvent extends MaterialEvent {
  final int materialGroupId;
  final int materialId;
  final MaterialRequestModel request;

  UpdateMaterialEvent({
    required super.origin,
    required this.materialGroupId,
    required this.materialId,
    required this.request,
  });
}

class DeleteMaterialEvent extends MaterialEvent {
  final int materialGroupId;
  final int materialId;

  DeleteMaterialEvent({
    required super.origin,
    required this.materialGroupId,
    required this.materialId,
  });
}
