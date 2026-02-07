// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockMaterialRepository mockMaterialRepository;
  late MockCourseRepository mockCourseRepository;
  late MaterialBloc materialBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockMaterialRepository = MockMaterialRepository();
    mockCourseRepository = MockCourseRepository();
    materialBloc = MaterialBloc(
      materialRepository: mockMaterialRepository,
      courseRepository: mockCourseRepository,
    );
  });

  tearDown(() {
    materialBloc.close();
  });

  group('MaterialBloc', () {
    test('initial state is MaterialsInitial with bloc origin', () {
      expect(materialBloc.state, isA<MaterialsInitial>());
    });

    group('FetchMaterialsScreenDataEvent', () {
      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsScreenDataFetched] when fetch succeeds',
        build: () {
          when(
            () => mockMaterialRepository.getMaterialGroups(),
          ).thenAnswer((_) async => MockModels.createMaterialGroups());
          when(
            () => mockMaterialRepository.getMaterials(),
          ).thenAnswer((_) async => MockModels.createMaterials());
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return materialBloc;
        },
        act: (bloc) =>
            bloc.add(FetchMaterialsScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsScreenDataFetched>()
              .having(
                (s) => s.materialGroups.length,
                'materialGroups length',
                2,
              )
              .having((s) => s.materials.length, 'materials length', 3)
              .having((s) => s.courses.length, 'courses length', 3),
        ],
        verify: (_) {
          verify(() => mockMaterialRepository.getMaterialGroups()).called(1);
          verify(() => mockMaterialRepository.getMaterials()).called(1);
          verify(() => mockCourseRepository.getCourses()).called(1);
        },
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when getMaterialGroups fails',
        build: () {
          when(
            () => mockMaterialRepository.getMaterialGroups(),
          ).thenThrow(ServerException(message: 'Server error'));
          return materialBloc;
        },
        act: (bloc) =>
            bloc.add(FetchMaterialsScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when getMaterials fails',
        build: () {
          when(
            () => mockMaterialRepository.getMaterialGroups(),
          ).thenAnswer((_) async => MockModels.createMaterialGroups());
          when(
            () => mockMaterialRepository.getMaterials(),
          ).thenThrow(NetworkException(message: 'Network error'));
          return materialBloc;
        },
        act: (bloc) =>
            bloc.add(FetchMaterialsScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ],
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] with generic message for unexpected errors',
        build: () {
          when(
            () => mockMaterialRepository.getMaterialGroups(),
          ).thenThrow(Exception('Unknown error'));
          return materialBloc;
        },
        act: (bloc) =>
            bloc.add(FetchMaterialsScreenDataEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('FetchMaterialScreenDataEvent', () {
      const materialGroupId = 1;
      const materialId = 2;

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialScreenDataFetched] with material when materialId is provided',
        build: () {
          when(
            () =>
                mockMaterialRepository.getMaterial(materialGroupId, materialId),
          ).thenAnswer((_) async => MockModels.createMaterial(id: materialId));
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          FetchMaterialScreenDataEvent(
            origin: EventOrigin.screen,
            materialGroupId: materialGroupId,
            materialId: materialId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialScreenDataFetched>().having(
            (s) => s.material?.id,
            'material id',
            materialId,
          ),
        ],
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialScreenDataFetched] with null material when materialId is null',
        build: () {
          when(
            () => mockCourseRepository.getCourses(),
          ).thenAnswer((_) async => MockModels.createCourses());
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          FetchMaterialScreenDataEvent(
            origin: EventOrigin.screen,
            materialGroupId: materialGroupId,
            materialId: null,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialScreenDataFetched>().having(
            (s) => s.material,
            'material',
            isNull,
          ),
        ],
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when getMaterial fails',
        build: () {
          when(
            () =>
                mockMaterialRepository.getMaterial(materialGroupId, materialId),
          ).thenThrow(NotFoundException(message: 'Material not found'));
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          FetchMaterialScreenDataEvent(
            origin: EventOrigin.screen,
            materialGroupId: materialGroupId,
            materialId: materialId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Material not found',
          ),
        ],
      );
    });

    group('FetchMaterialsEvent', () {
      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsFetched] when fetch succeeds without filters',
        build: () {
          when(
            () => mockMaterialRepository.getMaterials(
              groupId: null,
              shownOnCalendar: null,
            ),
          ).thenAnswer((_) async => MockModels.createMaterials());
          return materialBloc;
        },
        act: (bloc) =>
            bloc.add(FetchMaterialsEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsFetched>().having(
            (s) => s.materials.length,
            'materials length',
            3,
          ),
        ],
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsFetched] with filtered materials',
        build: () {
          when(
            () => mockMaterialRepository.getMaterials(
              groupId: 1,
              shownOnCalendar: true,
            ),
          ).thenAnswer((_) async => MockModels.createMaterials(count: 1));
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          FetchMaterialsEvent(
            origin: EventOrigin.screen,
            materialGroupId: 1,
            shownOnCalendar: true,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsFetched>().having(
            (s) => s.materials.length,
            'materials length',
            1,
          ),
        ],
        verify: (_) {
          verify(
            () => mockMaterialRepository.getMaterials(
              groupId: 1,
              shownOnCalendar: true,
            ),
          ).called(1);
        },
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when fetch fails',
        build: () {
          when(
            () => mockMaterialRepository.getMaterials(
              groupId: null,
              shownOnCalendar: null,
            ),
          ).thenThrow(ServerException(message: 'Failed to fetch'));
          return materialBloc;
        },
        act: (bloc) =>
            bloc.add(FetchMaterialsEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Failed to fetch',
          ),
        ],
      );
    });

    group('FetchMaterialEvent', () {
      const materialGroupId = 1;
      const materialId = 2;

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialFetched] when fetch succeeds',
        build: () {
          when(
            () =>
                mockMaterialRepository.getMaterial(materialGroupId, materialId),
          ).thenAnswer((_) async => MockModels.createMaterial(id: materialId));
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          FetchMaterialEvent(
            origin: EventOrigin.screen,
            materialGroupId: materialGroupId,
            materialId: materialId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialFetched>().having(
            (s) => s.material.id,
            'material id',
            materialId,
          ),
        ],
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when material not found',
        build: () {
          when(
            () =>
                mockMaterialRepository.getMaterial(materialGroupId, materialId),
          ).thenThrow(NotFoundException(message: 'Material not found'));
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          FetchMaterialEvent(
            origin: EventOrigin.screen,
            materialGroupId: materialGroupId,
            materialId: materialId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Material not found',
          ),
        ],
      );
    });

    group('DeleteMaterialGroupEvent', () {
      const materialGroupId = 1;

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialGroupDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockMaterialRepository.deleteMaterialGroup(materialGroupId),
          ).thenAnswer((_) async {});
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          DeleteMaterialGroupEvent(
            origin: EventOrigin.dialog,
            materialGroupId: materialGroupId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialGroupDeleted>().having(
            (s) => s.id,
            'id',
            materialGroupId,
          ),
        ],
        verify: (_) {
          verify(
            () => mockMaterialRepository.deleteMaterialGroup(materialGroupId),
          ).called(1);
        },
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when deletion fails',
        build: () {
          when(
            () => mockMaterialRepository.deleteMaterialGroup(materialGroupId),
          ).thenThrow(ServerException(message: 'Cannot delete'));
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          DeleteMaterialGroupEvent(
            origin: EventOrigin.dialog,
            materialGroupId: materialGroupId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Cannot delete',
          ),
        ],
      );
    });

    group('DeleteMaterialEvent', () {
      const materialGroupId = 1;
      const materialId = 2;

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockMaterialRepository.deleteMaterial(
              materialGroupId,
              materialId,
            ),
          ).thenAnswer((_) async {});
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          DeleteMaterialEvent(
            origin: EventOrigin.dialog,
            materialGroupId: materialGroupId,
            materialId: materialId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialDeleted>().having((s) => s.id, 'id', materialId),
        ],
        verify: (_) {
          verify(
            () => mockMaterialRepository.deleteMaterial(
              materialGroupId,
              materialId,
            ),
          ).called(1);
        },
      );

      blocTest<MaterialBloc, MaterialState>(
        'emits [MaterialsLoading, MaterialsError] when deletion fails',
        build: () {
          when(
            () => mockMaterialRepository.deleteMaterial(
              materialGroupId,
              materialId,
            ),
          ).thenThrow(NotFoundException(message: 'Material not found'));
          return materialBloc;
        },
        act: (bloc) => bloc.add(
          DeleteMaterialEvent(
            origin: EventOrigin.dialog,
            materialGroupId: materialGroupId,
            materialId: materialId,
          ),
        ),
        expect: () => [
          isA<MaterialsLoading>(),
          isA<MaterialsError>().having(
            (e) => e.message,
            'message',
            'Material not found',
          ),
        ],
      );
    });
  });
}
