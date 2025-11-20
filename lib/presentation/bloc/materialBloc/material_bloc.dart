import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/domain/repositories/material_repository.dart';
import 'package:heliumedu/presentation/bloc/materialBloc/material_event.dart';
import 'package:heliumedu/presentation/bloc/materialBloc/material_state.dart';

class MaterialBloc extends Bloc<MaterialEvent, MaterialState> {
  final MaterialRepository materialRepository;

  MaterialBloc({required this.materialRepository}) : super(MaterialInitial()) {
    on<FetchMaterialGroupsEvent>(_onFetchMaterialGroups);
    on<FetchMaterialGroupByIdEvent>(_onFetchMaterialGroupById);
    on<CreateMaterialGroupEvent>(_onCreateMaterialGroup);
    on<UpdateMaterialGroupEvent>(_onUpdateMaterialGroup);
    on<DeleteMaterialGroupEvent>(_onDeleteMaterialGroup);
    on<FetchAllMaterialsEvent>(_onFetchAllMaterials);
    on<FetchMaterialsEvent>(_onFetchMaterials);
    on<CreateMaterialEvent>(_onCreateMaterial);
    on<UpdateMaterialEvent>(_onUpdateMaterial);
    on<DeleteMaterialEvent>(_onDeleteMaterial);
  }

  // Fetch all material groups
  Future<void> _onFetchMaterialGroups(
    FetchMaterialGroupsEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialGroupsLoading());
    try {
      final materialGroups = await materialRepository.getMaterialGroups();
      emit(MaterialGroupsLoaded(materialGroups: materialGroups));
    } on AppException catch (e) {
      emit(MaterialGroupsError(message: e.message));
    } catch (e) {
      emit(MaterialGroupsError(message: 'An unexpected error occurred: $e'));
    }
  }

  // Fetch material group by ID
  Future<void> _onFetchMaterialGroupById(
    FetchMaterialGroupByIdEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialGroupDetailLoading());
    try {
      final materialGroup = await materialRepository.getMaterialGroupById(
        event.groupId,
      );
      emit(MaterialGroupDetailLoaded(materialGroup: materialGroup));
    } on AppException catch (e) {
      emit(MaterialGroupDetailError(message: e.message));
    } catch (e) {
      emit(
        MaterialGroupDetailError(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  // Create material group
  Future<void> _onCreateMaterialGroup(
    CreateMaterialGroupEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialGroupCreating());
    try {
      final materialGroup = await materialRepository.createMaterialGroup(
        event.request,
      );
      emit(MaterialGroupCreated(materialGroup: materialGroup));

      // Refresh the list after creation
      add(FetchMaterialGroupsEvent());
    } on AppException catch (e) {
      emit(MaterialGroupCreateError(message: e.message));
    } catch (e) {
      emit(
        MaterialGroupCreateError(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  // Update material group
  Future<void> _onUpdateMaterialGroup(
    UpdateMaterialGroupEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialGroupUpdating());
    try {
      final materialGroup = await materialRepository.updateMaterialGroup(
        event.groupId,
        event.request,
      );
      emit(MaterialGroupUpdated(materialGroup: materialGroup));

      // Refresh the list after update
      add(FetchMaterialGroupsEvent());
    } on AppException catch (e) {
      emit(MaterialGroupUpdateError(message: e.message));
    } catch (e) {
      emit(
        MaterialGroupUpdateError(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  // Delete material group
  Future<void> _onDeleteMaterialGroup(
    DeleteMaterialGroupEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialGroupDeleting());
    try {
      await materialRepository.deleteMaterialGroup(event.groupId);
      emit(MaterialGroupDeleted());

      // Refresh the list after deletion
      add(FetchMaterialGroupsEvent());
    } on AppException catch (e) {
      emit(MaterialGroupDeleteError(message: e.message));
    } catch (e) {
      emit(
        MaterialGroupDeleteError(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  // Fetch all materials
  Future<void> _onFetchAllMaterials(
    FetchAllMaterialsEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading());
    try {
      final materials = await materialRepository.getAllMaterials();
      emit(MaterialsLoaded(materials: materials));
    } on AppException catch (e) {
      emit(MaterialsError(message: e.message));
    } catch (e) {
      emit(MaterialsError(message: 'An unexpected error occurred: $e'));
    }
  }

  // Fetch materials
  Future<void> _onFetchMaterials(
    FetchMaterialsEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading());
    try {
      final materials = await materialRepository.getMaterials(event.groupId);
      emit(MaterialsLoaded(materials: materials));
    } on AppException catch (e) {
      emit(MaterialsError(message: e.message));
    } catch (e) {
      emit(MaterialsError(message: 'An unexpected error occurred: $e'));
    }
  }

  // Create material
  Future<void> _onCreateMaterial(
    CreateMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialCreating());
    try {
      final material = await materialRepository.createMaterial(event.request);
      emit(MaterialCreated(material: material));

      // Refresh the list after creation
      add(FetchMaterialsEvent(groupId: event.request.materialGroup));
    } on AppException catch (e) {
      emit(MaterialCreateError(message: e.message));
    } catch (e) {
      emit(MaterialCreateError(message: 'An unexpected error occurred: $e'));
    }
  }

  // Update material
  Future<void> _onUpdateMaterial(
    UpdateMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialUpdating());
    try {
      final material = await materialRepository.updateMaterial(
        event.groupId,
        event.materialId,
        event.request,
      );
      emit(MaterialUpdated(material: material));

      // Refresh the list after update
      add(FetchMaterialsEvent(groupId: event.groupId));
    } on AppException catch (e) {
      emit(MaterialUpdateError(message: e.message));
    } catch (e) {
      emit(MaterialUpdateError(message: 'An unexpected error occurred: $e'));
    }
  }

  // Delete material
  Future<void> _onDeleteMaterial(
    DeleteMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialDeleting());
    try {
      await materialRepository.deleteMaterial(event.groupId, event.materialId);
      emit(MaterialDeleted());

      // Refresh the list after deletion
      add(FetchMaterialsEvent(groupId: event.groupId));
    } on AppException catch (e) {
      emit(MaterialDeleteError(message: e.message));
    } catch (e) {
      emit(MaterialDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }
}
