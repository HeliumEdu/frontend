// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/material_repository.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart';

class MaterialBloc extends Bloc<MaterialEvent, MaterialState> {
  final MaterialRepository materialRepository;
  final CourseRepository courseRepository;

  MaterialBloc({
    required this.materialRepository,
    required this.courseRepository,
  }) : super(MaterialsInitial(origin: EventOrigin.bloc)) {
    on<FetchMaterialsScreenDataEvent>(_onFetchMaterialsScreenData);
    on<FetchMaterialScreenDataEvent>(_onFetchMaterialScreenDataEvent);
    on<FetchMaterialsEvent>(_onFetchMaterials);
    on<FetchMaterialEvent>(onFetchMaterial);
    on<CreateMaterialGroupEvent>(_onCreateMaterialGroup);
    on<UpdateMaterialGroupEvent>(_onUpdateMaterialGroup);
    on<DeleteMaterialGroupEvent>(_onDeleteMaterialGroup);
    on<CreateMaterialEvent>(_onCreateMaterial);
    on<UpdateMaterialEvent>(_onUpdateMaterial);
    on<DeleteMaterialEvent>(_onDeleteMaterial);
  }

  Future<void> _onFetchMaterialsScreenData(
    FetchMaterialsScreenDataEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final materialGroups = await materialRepository.getMaterialGroups();
      final materials = await materialRepository.getMaterials();
      final courses = await courseRepository.getCourses();
      emit(
        MaterialsScreenDataFetched(
          origin: event.origin,
          materialGroups: materialGroups,
          materials: materials,
          courses: courses,
        ),
      );
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchMaterialScreenDataEvent(
    FetchMaterialScreenDataEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final MaterialModel? material;
      if (event.materialId != null) {
        material = await materialRepository.getMaterial(
          event.materialGroupId,
          event.materialId!,
        );
      } else {
        material = null;
      }

      final courses = await courseRepository.getCourses();
      emit(
        MaterialScreenDataFetched(
          origin: event.origin,
          material: material,
          courses: courses,
        ),
      );
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateMaterialGroup(
    CreateMaterialGroupEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final materialGroup = await materialRepository.createMaterialGroup(
        event.request,
      );
      emit(
        MaterialGroupCreated(
          origin: event.origin,
          materialGroup: materialGroup,
        ),
      );
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateMaterialGroup(
    UpdateMaterialGroupEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final materialGroup = await materialRepository.updateMaterialGroup(
        event.materialGroupId,
        event.request,
      );
      emit(
        MaterialGroupUpdated(
          origin: event.origin,
          materialGroup: materialGroup,
        ),
      );
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMaterialGroup(
    DeleteMaterialGroupEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      await materialRepository.deleteMaterialGroup(event.materialGroupId);
      emit(
        MaterialGroupDeleted(origin: event.origin, id: event.materialGroupId),
      );
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> onFetchMaterial(
    FetchMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final material = await materialRepository.getMaterial(
        event.materialGroupId,
        event.materialId,
      );
      emit(MaterialFetched(origin: event.origin, material: material));
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchMaterials(
    FetchMaterialsEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final materials = await materialRepository.getMaterials(
        groupId: event.materialGroupId,
        shownOnCalendar: event.shownOnCalendar,
      );
      emit(MaterialsFetched(origin: event.origin, materials: materials));
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateMaterial(
    CreateMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final material = await materialRepository.createMaterial(
        event.materialGroupId,
        event.request,
      );
      emit(MaterialCreated(origin: event.origin, material: material));
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  // Update material
  Future<void> _onUpdateMaterial(
    UpdateMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      final material = await materialRepository.updateMaterial(
        event.materialGroupId,
        event.materialId,
        event.request,
      );
      emit(MaterialUpdated(origin: event.origin, material: material));
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMaterial(
    DeleteMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialsLoading(origin: event.origin));
    try {
      await materialRepository.deleteMaterial(
        event.materialGroupId,
        event.materialId,
      );
      emit(MaterialDeleted(origin: event.origin, id: event.materialId));
    } on HeliumException catch (e) {
      emit(MaterialsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        MaterialsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}
