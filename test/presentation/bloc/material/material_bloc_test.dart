// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockResourceRepository mockResourceRepository;
  late MockCourseRepository mockCourseRepository;
  late ResourceBloc resourceBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockResourceRepository = MockResourceRepository();
    mockCourseRepository = MockCourseRepository();
    resourceBloc = ResourceBloc(
      resourceRepository: mockResourceRepository,
      courseRepository: mockCourseRepository,
    );
  });

  tearDown(() {
    resourceBloc.close();
  });

  group('ResourceBloc', () {
    test('initial state is ResourcesInitial with bloc origin', () {
      expect(resourceBloc.state, isA<ResourcesInitial>());
    });

    group('FetchResourcesScreenDataEvent', () {
      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesScreenDataFetched] when fetch succeeds',
        build: () {
          when(
            () => mockResourceRepository.getResourceGroups(),
          ).thenAnswer((_) async => MockModels.createResourceGroups());
          when(
            () => mockResourceRepository.getResources(),
          ).thenAnswer((_) async => MockModels.createResources());
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return resourceBloc;
        },
        act: (bloc) =>
            bloc.add(FetchResourcesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesScreenDataFetched>()
              .having(
                (s) => s.resourceGroups.length,
                'resourceGroups length',
                2,
              )
              .having((s) => s.resources.length, 'resources length', 3)
              .having((s) => s.courses.length, 'courses length', 3),
        ],
        verify: (_) {
          verify(() => mockResourceRepository.getResourceGroups()).called(1);
          verify(() => mockResourceRepository.getResources()).called(1);
          verify(() => mockCourseRepository.getCourses()).called(1);
        },
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when getResourceGroups fails',
        build: () {
          when(
            () => mockResourceRepository.getResourceGroups(),
          ).thenThrow(ServerException(message: 'Server error'));
          return resourceBloc;
        },
        act: (bloc) =>
            bloc.add(FetchResourcesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when getResources fails',
        build: () {
          when(
            () => mockResourceRepository.getResourceGroups(),
          ).thenAnswer((_) async => MockModels.createResourceGroups());
          when(
            () => mockResourceRepository.getResources(),
          ).thenThrow(NetworkException(message: 'Network error'));
          return resourceBloc;
        },
        act: (bloc) =>
            bloc.add(FetchResourcesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ],
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] with generic message for unexpected errors',
        build: () {
          when(
            () => mockResourceRepository.getResourceGroups(),
          ).thenThrow(Exception('Unknown error'));
          return resourceBloc;
        },
        act: (bloc) =>
            bloc.add(FetchResourcesScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('FetchResourceScreenDataEvent', () {
      const resourceGroupId = 1;
      const resourceId = 2;

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourceScreenDataFetched] with resource when resourceId is provided',
        build: () {
          when(
            () =>
                mockResourceRepository.getResource(resourceGroupId, resourceId),
          ).thenAnswer((_) async => MockModels.createResource(id: resourceId));
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          FetchResourceScreenDataEvent(
            origin: EventOrigin.screen,
            resourceGroupId: resourceGroupId,
            resourceId: resourceId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourceScreenDataFetched>().having(
            (s) => s.resource?.id,
            'resource id',
            resourceId,
          ),
        ],
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourceScreenDataFetched] with null resource when resourceId is null',
        build: () {
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          FetchResourceScreenDataEvent(
            origin: EventOrigin.screen,
            resourceGroupId: resourceGroupId,
            resourceId: null,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourceScreenDataFetched>().having(
            (s) => s.resource,
            'resource',
            isNull,
          ),
        ],
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when getResource fails',
        build: () {
          when(
            () =>
                mockResourceRepository.getResource(resourceGroupId, resourceId),
          ).thenThrow(NotFoundException(message: 'Resource not found'));
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          FetchResourceScreenDataEvent(
            origin: EventOrigin.screen,
            resourceGroupId: resourceGroupId,
            resourceId: resourceId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Resource not found',
          ),
        ],
      );
    });

    group('FetchResourcesEvent', () {
      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesFetched] when fetch succeeds without filters',
        build: () {
          when(
            () => mockResourceRepository.getResources(
              groupId: null,
              shownOnCalendar: null,
            ),
          ).thenAnswer((_) async => MockModels.createResources());
          return resourceBloc;
        },
        act: (bloc) =>
            bloc.add(FetchResourcesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesFetched>().having(
            (s) => s.resources.length,
            'resources length',
            3,
          ),
        ],
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesFetched] with filtered resources',
        build: () {
          when(
            () => mockResourceRepository.getResources(
              groupId: 1,
              shownOnCalendar: true,
            ),
          ).thenAnswer((_) async => MockModels.createResources(count: 1));
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          FetchResourcesEvent(
            origin: EventOrigin.screen,
            resourceGroupId: 1,
            shownOnCalendar: true,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesFetched>().having(
            (s) => s.resources.length,
            'resources length',
            1,
          ),
        ],
        verify: (_) {
          verify(
            () => mockResourceRepository.getResources(
              groupId: 1,
              shownOnCalendar: true,
            ),
          ).called(1);
        },
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when fetch fails',
        build: () {
          when(
            () => mockResourceRepository.getResources(
              groupId: null,
              shownOnCalendar: null,
            ),
          ).thenThrow(ServerException(message: 'Failed to fetch'));
          return resourceBloc;
        },
        act: (bloc) =>
            bloc.add(FetchResourcesEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Failed to fetch',
          ),
        ],
      );
    });

    group('FetchResourceEvent', () {
      const resourceGroupId = 1;
      const resourceId = 2;

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourceFetched] when fetch succeeds',
        build: () {
          when(
            () =>
                mockResourceRepository.getResource(resourceGroupId, resourceId),
          ).thenAnswer((_) async => MockModels.createResource(id: resourceId));
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          FetchResourceEvent(
            origin: EventOrigin.screen,
            resourceGroupId: resourceGroupId,
            resourceId: resourceId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourceFetched>().having(
            (s) => s.resource.id,
            'resource id',
            resourceId,
          ),
        ],
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when resource not found',
        build: () {
          when(
            () =>
                mockResourceRepository.getResource(resourceGroupId, resourceId),
          ).thenThrow(NotFoundException(message: 'Resource not found'));
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          FetchResourceEvent(
            origin: EventOrigin.screen,
            resourceGroupId: resourceGroupId,
            resourceId: resourceId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Resource not found',
          ),
        ],
      );
    });

    group('DeleteResourceGroupEvent', () {
      const resourceGroupId = 1;

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourceGroupDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockResourceRepository.deleteResourceGroup(resourceGroupId),
          ).thenAnswer((_) async {});
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          DeleteResourceGroupEvent(
            origin: EventOrigin.dialog,
            resourceGroupId: resourceGroupId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourceGroupDeleted>().having(
            (s) => s.id,
            'id',
            resourceGroupId,
          ),
        ],
        verify: (_) {
          verify(
            () => mockResourceRepository.deleteResourceGroup(resourceGroupId),
          ).called(1);
        },
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when deletion fails',
        build: () {
          when(
            () => mockResourceRepository.deleteResourceGroup(resourceGroupId),
          ).thenThrow(ServerException(message: 'Cannot delete'));
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          DeleteResourceGroupEvent(
            origin: EventOrigin.dialog,
            resourceGroupId: resourceGroupId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Cannot delete',
          ),
        ],
      );
    });

    group('DeleteResourceEvent', () {
      const resourceGroupId = 1;
      const resourceId = 2;

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourceDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockResourceRepository.deleteResource(
              resourceGroupId,
              resourceId,
            ),
          ).thenAnswer((_) async {});
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          DeleteResourceEvent(
            origin: EventOrigin.dialog,
            resourceGroupId: resourceGroupId,
            resourceId: resourceId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourceDeleted>().having((s) => s.id, 'id', resourceId),
        ],
        verify: (_) {
          verify(
            () => mockResourceRepository.deleteResource(
              resourceGroupId,
              resourceId,
            ),
          ).called(1);
        },
      );

      blocTest<ResourceBloc, ResourceState>(
        'emits [ResourcesLoading, ResourcesError] when deletion fails',
        build: () {
          when(
            () => mockResourceRepository.deleteResource(
              resourceGroupId,
              resourceId,
            ),
          ).thenThrow(NotFoundException(message: 'Resource not found'));
          return resourceBloc;
        },
        act: (bloc) => bloc.add(
          DeleteResourceEvent(
            origin: EventOrigin.dialog,
            resourceGroupId: resourceGroupId,
            resourceId: resourceId,
          ),
        ),
        expect: () => [
          isA<ResourcesLoading>(),
          isA<ResourcesError>().having(
            (e) => e.message,
            'message',
            'Resource not found',
          ),
        ],
      );
    });
  });
}
