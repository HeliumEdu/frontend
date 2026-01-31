// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/material_group_model.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/material_repository_impl.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/material_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart'
    as material_state;
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/dialogs/material_group_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/group_dropdown.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/material_title_label.dart';
import 'package:heliumapp/presentation/widgets/pill_badge.dart';
import 'package:heliumapp/presentation/widgets/responsive_card_grid.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialsScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  MaterialsScreen({super.key});

  StatefulWidget buildScreen() => const MaterialsProvidedScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MaterialBloc(
            materialRepository: MaterialRepositoryImpl(
              remoteDataSource: MaterialRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: buildScreen(),
    );
  }
}

class MaterialsProvidedScreen extends StatefulWidget {
  const MaterialsProvidedScreen({super.key});

  @override
  State<MaterialsProvidedScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState
    extends BasePageScreenState<MaterialsProvidedScreen> {
  @override
  String get screenTitle => 'Materials';

  @override
  VoidCallback get actionButtonCallback => () {
    if (_selectedGroupId != null) {
      context.push(
        AppRoutes.materialAddScreen,
        extra: MaterialAddArgs(
          materialBloc: context.read<MaterialBloc>(),
          materialGroupId: _selectedGroupId!,
          isEdit: false,
        ),
      );
    } else {
      showSnackBar(context, 'Create a group first', isError: true);
    }
  };

  @override
  bool get showActionButton => _materialGroups.isNotEmpty;

  // State
  List<MaterialGroupModel> _materialGroups = [];
  final Map<int, List<MaterialModel>> _materialsMap = {};
  Map<int, CourseModel> _coursesMap = {};
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();

    context.read<MaterialBloc>().add(
      FetchMaterialsScreenDataEvent(origin: EventOrigin.screen),
    );
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<MaterialBloc, material_state.MaterialState>(
        listener: (context, state) {
          if (state is material_state.MaterialsScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is material_state.MaterialGroupCreated) {
            showSnackBar(context, 'Group saved');

            setState(() {
              _materialGroups.add(state.materialGroup);
              Sort.byTitle(_materialGroups);
              _selectedGroupId = state.materialGroup.id;
              _materialsMap[_selectedGroupId!] = [];
            });
          } else if (state is material_state.MaterialGroupUpdated) {
            showSnackBar(context, 'Material group saved');

            setState(() {
              _materialGroups[_materialGroups.indexWhere(
                    (g) => g.id == _selectedGroupId,
                  )] =
                  state.materialGroup;
              Sort.byTitle(_materialGroups);
            });
          } else if (state is material_state.MaterialGroupDeleted) {
            showSnackBar(context, 'Material group deleted');

            setState(() {
              _materialGroups.removeWhere((g) => g.id == state.id);
              if (_materialGroups.isEmpty) {
                _selectedGroupId = null;
              } else {
                // Reset if selected group was deleted
                if (!_materialGroups.any((g) => g.id == _selectedGroupId)) {
                  _selectedGroupId = _materialGroups.first.id;
                }
              }
            });
          } else if (state is material_state.MaterialCreated) {
            setState(() {
              _materialsMap[_selectedGroupId]!.add(state.material);
              Sort.byTitle(_materialsMap[_selectedGroupId!]!);
            });
          } else if (state is material_state.MaterialUpdated) {
            setState(() {
              final index = _materialsMap[_selectedGroupId]!.indexWhere(
                (m) => m.id == state.material.id,
              );
              _materialsMap[_selectedGroupId]![index] = state.material;
              Sort.byTitle(_materialsMap[_selectedGroupId!]!);
            });
          } else if (state is material_state.MaterialDeleted) {
            showSnackBar(context, 'Material deleted');

            setState(() {
              _materialsMap[_selectedGroupId!]!.removeWhere(
                (m) => m.id == state.id,
              );
              Sort.byTitle(_materialsMap[_selectedGroupId!]!);
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GroupDropdown(
        groups: _materialGroups,
        initialSelection: _materialGroups.firstWhereOrNull(
          (g) => g.id == _selectedGroupId,
        ),
        onChanged: (value) {
          // The "+" button has a null value
          if (value == null) return;
          if (value.id == _selectedGroupId) return;

          setState(() {
            _selectedGroupId = value.id;
          });
        },
        onCreate: () {
          showMaterialGroupDialog(parentContext: context, isEdit: false);
        },
        onEdit: (group) {
          showMaterialGroupDialog(
            parentContext: context,
            isEdit: true,
            group: group,
          );
        },
        onDelete: (g) {
          context.read<MaterialBloc>().add(
            DeleteMaterialGroupEvent(
              origin: EventOrigin.screen,
              materialGroupId: g.id,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<MaterialBloc, material_state.MaterialState>(
      builder: (context, state) {
        if (state is material_state.MaterialsLoading) {
          return buildLoading();
        }

        if (state is material_state.MaterialsError &&
            state.origin == EventOrigin.screen) {
          return buildReload(state.message!, () {
            context.read<MaterialBloc>().add(
              FetchMaterialsScreenDataEvent(origin: EventOrigin.screen),
            );
          });
        }

        if (_materialGroups.isEmpty) {
          return buildEmptyPage(
            icon: Icons.book,
            title: "You haven't added any groups yet",
            message: 'Click "+ Group" to get started',
          );
        }

        if (_materialsMap[_selectedGroupId!]!.isEmpty) {
          return buildEmptyPage(
            icon: Icons.book,
            title: "You haven't added any materials yet",
            message: 'Click "+" to get started',
          );
        }

        return _buildMaterialsList();
      },
    );
  }

  Widget _buildMaterialsList() {
    return Expanded(
      child: ResponsiveCardGrid<MaterialModel>(
        items: _materialsMap[_selectedGroupId!]!,
        itemBuilder: (context, material) =>
            _buildMaterialCard(context, material),
      ),
    );
  }

  void _populateInitialStateData(
    material_state.MaterialsScreenDataFetched state,
  ) {
    setState(() {
      _materialGroups = state.materialGroups;
      Sort.byTitle(_materialGroups);

      for (var group in _materialGroups) {
        _materialsMap[group.id] = state.materials
            .where((m) => m.materialGroup == group.id)
            .toList();
        Sort.byTitle(_materialsMap[group.id]!);
      }

      _coursesMap = {for (var course in state.courses) course.id: course};

      if (_materialGroups.isNotEmpty) {
        _selectedGroupId = _materialGroups.first.id;
      }

      isLoading = false;
    });
  }

  Widget _buildMaterialCard(BuildContext context, MaterialModel material) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MaterialTitleLabel(
                    title: material.title,
                    userSettings: userSettings,
                  ),
                ),
                const SizedBox(width: 8),
                if (material.website.isNotEmpty) ...[
                  HeliumIconButton(
                    onPressed: () {
                      launchUrl(
                        Uri.parse(material.website),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: Icons.link_outlined,
                    color: context.semanticColors.success,
                  ),
                  const SizedBox(width: 8),
                ],
                HeliumIconButton(
                  onPressed: () {
                    context.push(
                      AppRoutes.materialAddScreen,
                      extra: MaterialAddArgs(
                        materialBloc: context.read<MaterialBloc>(),
                        materialGroupId: _selectedGroupId!,
                        materialId: material.id,
                        isEdit: true,
                      ),
                    );
                  },
                  icon: Icons.edit_outlined,
                ),
                const SizedBox(width: 8),
                HeliumIconButton(
                  onPressed: () {
                    showConfirmDeleteDialog(
                      parentContext: context,
                      item: material,
                      onDelete: (m) {
                        context.read<MaterialBloc>().add(
                          DeleteMaterialEvent(
                            origin: EventOrigin.screen,
                            materialGroupId: m.materialGroup,
                            materialId: m.id,
                          ),
                        );
                      },
                    );
                  },
                  icon: Icons.delete_outline,
                  color: context.colorScheme.error,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status and Price Row
            Row(
              children: [
                ...[
                  PillBadge(text: MaterialConstants.status[material.status]),
                  const SizedBox(width: 8),
                  if (MaterialConstants.status[material.status] !=
                      MaterialConstants.condition[material.condition])
                    PillBadge(
                      text: MaterialConstants.condition[material.condition],
                    ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                if (material.price != null && material.price!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    material.price!,
                    style: context.cTextStyle.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 11,
                        tablet: 13,
                        desktop: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (material.courses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: material.courses.map((courseId) {
                  final course = _coursesMap[courseId];
                  if (course == null) {
                    return const SizedBox.shrink();
                  }

                  return CourseTitleLabel(
                    title: course.title,
                    color: course.color,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            if (material.details != null && material.details!.isNotEmpty) ...[
              const Divider(),

              const SizedBox(height: 12),

              Html(
                data: material.details!,
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(
                      Responsive.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
