import 'package:heliumedu/data/models/planner/material_group_request_model.dart';
import 'package:heliumedu/data/models/planner/material_request_model.dart';

abstract class MaterialEvent {}

class FetchMaterialGroupsEvent extends MaterialEvent {}

class FetchMaterialGroupByIdEvent extends MaterialEvent {
  final int groupId;

  FetchMaterialGroupByIdEvent({required this.groupId});
}

class CreateMaterialGroupEvent extends MaterialEvent {
  final MaterialGroupRequestModel request;

  CreateMaterialGroupEvent({required this.request});
}

class UpdateMaterialGroupEvent extends MaterialEvent {
  final int groupId;
  final MaterialGroupRequestModel request;

  UpdateMaterialGroupEvent({required this.groupId, required this.request});
}

class DeleteMaterialGroupEvent extends MaterialEvent {
  final int groupId;

  DeleteMaterialGroupEvent({required this.groupId});
}

// Materials Events
class FetchAllMaterialsEvent extends MaterialEvent {}

class FetchMaterialsEvent extends MaterialEvent {
  final int groupId;

  FetchMaterialsEvent({required this.groupId});
}

class CreateMaterialEvent extends MaterialEvent {
  final MaterialRequestModel request;

  CreateMaterialEvent({required this.request});
}

class UpdateMaterialEvent extends MaterialEvent {
  final int groupId;
  final int materialId;
  final MaterialRequestModel request;

  UpdateMaterialEvent({
    required this.groupId,
    required this.materialId,
    required this.request,
  });
}

class DeleteMaterialEvent extends MaterialEvent {
  final int groupId;
  final int materialId;

  DeleteMaterialEvent({required this.groupId, required this.materialId});
}
