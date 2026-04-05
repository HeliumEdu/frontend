// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';

class ResourceBloc extends Bloc<ResourceEvent, ResourceState> {
  final ResourceRepository resourceRepository;
  final CourseRepository courseRepository;
  final NoteRepository noteRepository;

  ResourceBloc({
    required this.resourceRepository,
    required this.courseRepository,
    required this.noteRepository,
  }) : super(ResourcesInitial(origin: EventOrigin.bloc)) {
    on<FetchResourcesScreenDataEvent>(_onFetchResourcesScreenData);
    on<FetchResourceScreenDataEvent>(_onFetchResourceScreenDataEvent);
    on<FetchResourcesEvent>(_onFetchResources);
    on<FetchResourceEvent>(_onFetchResource);
    on<CreateResourceGroupEvent>(_onCreateResourceGroup);
    on<UpdateResourceGroupEvent>(_onUpdateResourceGroup);
    on<DeleteResourceGroupEvent>(_onDeleteResourceGroup);
    on<CreateResourceEvent>(_onCreateResource);
    on<UpdateResourceEvent>(_onUpdateResource);
    on<DeleteResourceEvent>(_onDeleteResource);
  }

  Future<void> _onFetchResourcesScreenData(
    FetchResourcesScreenDataEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final results = await Future.wait([
        resourceRepository.getResourceGroups(forceRefresh: event.forceRefresh),
        resourceRepository.getResources(forceRefresh: event.forceRefresh),
        courseRepository.getCourses(forceRefresh: event.forceRefresh),
        noteRepository.getNotes(linkedEntityType: 'resource', includeContent: true, forceRefresh: event.forceRefresh),
      ]);
      final resourceGroups = results[0] as List<ResourceGroupModel>;
      final resources = results[1] as List<ResourceModel>;
      final courses = results[2] as List<CourseModel>;
      final notes = results[3] as List<NoteModel>;
      emit(
        ResourcesScreenDataFetched(
          origin: event.origin,
          resourceGroups: resourceGroups,
          resources: resources,
          courses: courses,
          notes: notes,
        ),
      );
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onFetchResourceScreenDataEvent(
    FetchResourceScreenDataEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final results = await Future.wait([
        if (event.resourceId != null)
          resourceRepository.getResource(
            groupId: event.resourceGroupId,
            resourceId: event.resourceId!,
          ),
        courseRepository.getCourses(),
        if (event.resourceId != null)
          noteRepository.getNotes(resourceId: event.resourceId, includeContent: true),
      ]);

      final ResourceModel? resource;
      final List<CourseModel> courses;
      NoteModel? linkedNote;

      if (event.resourceId != null) {
        resource = results[0] as ResourceModel;
        courses = results[1] as List<CourseModel>;
        final notes = results[2] as List<NoteModel>;
        linkedNote = notes.isNotEmpty ? notes.first : null;
      } else {
        resource = null;
        courses = results[0] as List<CourseModel>;
      }

      emit(
        ResourceScreenDataFetched(
          origin: event.origin,
          resource: resource,
          courses: courses,
          linkedNote: linkedNote,
        ),
      );
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onCreateResourceGroup(
    CreateResourceGroupEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final resourceGroup = await resourceRepository.createResourceGroup(
        request: event.request,
      );
      emit(
        ResourceGroupCreated(
          origin: event.origin,
          resourceGroup: resourceGroup,
        ),
      );
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onUpdateResourceGroup(
    UpdateResourceGroupEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final resourceGroup = await resourceRepository.updateResourceGroup(
        id: event.resourceGroupId,
        request: event.request,
      );
      emit(
        ResourceGroupUpdated(
          origin: event.origin,
          resourceGroup: resourceGroup,
        ),
      );
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onDeleteResourceGroup(
    DeleteResourceGroupEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      await resourceRepository.deleteResourceGroup(id: event.resourceGroupId);
      emit(
        ResourceGroupDeleted(origin: event.origin, id: event.resourceGroupId),
      );
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onFetchResource(
    FetchResourceEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final resource = await resourceRepository.getResource(
        groupId: event.resourceGroupId,
        resourceId: event.resourceId,
      );
      emit(ResourceFetched(origin: event.origin, resource: resource));
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onFetchResources(
    FetchResourcesEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final resources = await resourceRepository.getResources(
        groupId: event.resourceGroupId,
        shownOnCalendar: event.shownOnCalendar,
      );
      emit(ResourcesFetched(origin: event.origin, resources: resources));
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onCreateResource(
    CreateResourceEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final resource = await resourceRepository.createResource(
        groupId: event.resourceGroupId,
        request: event.request,
      );
      emit(ResourceCreated(
        origin: event.origin,
        resource: resource,
        redirectToNotebook: event.redirectToNotebook,
      ));
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onUpdateResource(
    UpdateResourceEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      final resource = await resourceRepository.updateResource(
        groupId: event.resourceGroupId,
        resourceId: event.resourceId,
        request: event.request,
      );
      emit(ResourceUpdated(
        origin: event.origin,
        resource: resource,
        redirectToNotebook: event.redirectToNotebook,
      ));
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onDeleteResource(
    DeleteResourceEvent event,
    Emitter<ResourceState> emit,
  ) async {
    emit(ResourcesLoading(origin: event.origin));
    try {
      await resourceRepository.deleteResource(
        groupId: event.resourceGroupId,
        resourceId: event.resourceId,
      );
      emit(ResourceDeleted(origin: event.origin, id: event.resourceId));
    } on HeliumException catch (e) {
      emit(ResourcesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ResourcesError(
          origin: event.origin,
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }
}
