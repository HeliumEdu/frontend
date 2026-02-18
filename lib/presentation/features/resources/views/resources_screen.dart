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
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/resource_repository_impl.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/resources/dialogs/resource_group_dialog.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/resources/views/resource_add_screen.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/components/group_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/layout/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/ui/components/pill_badge.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_card_grid.dart';
import 'package:heliumapp/presentation/features/resources/constants/resource_constants.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  ResourcesScreen({super.key});

  StatefulWidget buildScreen() => const _ResourcesProvidedScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ResourceBloc(
            resourceRepository: ResourceRepositoryImpl(
              remoteDataSource: ResourceRemoteDataSourceImpl(
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

class _ResourcesProvidedScreen extends StatefulWidget {
  const _ResourcesProvidedScreen();

  @override
  State<_ResourcesProvidedScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState
    extends BasePageScreenState<_ResourcesProvidedScreen> {
  @override
  String get screenTitle => 'Resources';

  @override
  VoidCallback get actionButtonCallback => () {
    if (_selectedGroupId != null) {
      showResourceAdd(
        context,
        resourceGroupId: _selectedGroupId!,
        isEdit: false,
      );
    } else {
      showSnackBar(context, 'Create a group first', isError: true);
    }
  };

  @override
  bool get showActionButton => _resourceGroups.isNotEmpty;

  // State
  List<ResourceGroupModel> _resourceGroups = [];
  final Map<int, List<ResourceModel>> _resourcesMap = {};
  Map<int, CourseModel> _coursesMap = {};
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();

    context.read<ResourceBloc>().add(
      FetchResourcesScreenDataEvent(origin: EventOrigin.screen),
    );
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ResourceBloc, ResourceState>(
        listener: (context, state) {
          if (state is ResourcesScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is ResourceGroupCreated) {
            showSnackBar(context, 'Group created');

            setState(() {
              _resourceGroups.add(state.resourceGroup);
              Sort.byTitle(_resourceGroups);
              _selectedGroupId = state.resourceGroup.id;
              _resourcesMap[_selectedGroupId!] = [];
            });
          } else if (state is ResourceGroupUpdated) {
            // No snackbar on updates

            setState(() {
              _resourceGroups[_resourceGroups.indexWhere(
                    (g) => g.id == state.resourceGroup.id,
                  )] =
                  state.resourceGroup;
              Sort.byTitle(_resourceGroups);
            });
          } else if (state is ResourceGroupDeleted) {
            showSnackBar(context, 'Resource group deleted');

            setState(() {
              _resourceGroups.removeWhere((g) => g.id == state.id);
              if (_resourceGroups.isEmpty) {
                _selectedGroupId = null;
              } else {
                // Reset if selected group was deleted
                if (!_resourceGroups.any((g) => g.id == _selectedGroupId)) {
                  _selectedGroupId = _resourceGroups.first.id;
                }
              }
            });
          } else if (state is ResourceCreated) {
            if (_selectedGroupId == null) return;

            setState(() {
              _resourcesMap[_selectedGroupId]!.add(state.resource);
              Sort.byTitle(_resourcesMap[_selectedGroupId]!);
            });
          } else if (state is ResourceUpdated) {
            if (_selectedGroupId == null) return;

            setState(() {
              final index = _resourcesMap[_selectedGroupId]!.indexWhere(
                (m) => m.id == state.resource.id,
              );
              _resourcesMap[_selectedGroupId]![index] = state.resource;
              Sort.byTitle(_resourcesMap[_selectedGroupId]!);
            });
          } else if (state is ResourceDeleted) {
            if (_selectedGroupId == null) return;

            showSnackBar(context, 'Resource deleted');

            setState(() {
              _resourcesMap[_selectedGroupId]!.removeWhere(
                (m) => m.id == state.id,
              );
              Sort.byTitle(_resourcesMap[_selectedGroupId]!);
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
        groups: _resourceGroups,
        initialSelection: _resourceGroups.firstWhereOrNull(
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
          showResourceGroupDialog(parentContext: context, isEdit: false);
        },
        onEdit: (group) {
          showResourceGroupDialog(
            parentContext: context,
            isEdit: true,
            group: group,
          );
        },
        onDelete: (g) {
          context.read<ResourceBloc>().add(
            DeleteResourceGroupEvent(
              origin: EventOrigin.screen,
              resourceGroupId: g.id,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<ResourceBloc, ResourceState>(
      builder: (context, state) {
        if (state is ResourcesLoading && state.origin == EventOrigin.screen) {
          return const LoadingIndicator();
        }

        if (state is ResourcesError && state.origin == EventOrigin.screen) {
          return ErrorCard(
            message: state.message!,
            onReload: () {
              context.read<ResourceBloc>().add(
                FetchResourcesScreenDataEvent(origin: EventOrigin.screen),
              );
            },
          );
        }

        if (_resourceGroups.isEmpty) {
          return const EmptyCard(
            icon: Icons.book,
            title: "You haven't added any groups yet",
            message: 'Click "+ Group" to get started',
          );
        }

        if (_selectedGroupId == null ||
            (_resourcesMap[_selectedGroupId]?.isEmpty ?? true)) {
          return const EmptyCard(
            icon: Icons.book,
            title: "You haven't added any resources yet",
            message: 'Click "+" to get started',
          );
        }

        return _buildResourcesList();
      },
    );
  }

  Widget _buildResourcesList() {
    if (_selectedGroupId == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: ResponsiveCardGrid<ResourceModel>(
        items: _resourcesMap[_selectedGroupId]!,
        itemBuilder: (context, resource) =>
            _buildResourceCard(context, resource),
      ),
    );
  }

  void _populateInitialStateData(ResourcesScreenDataFetched state) {
    setState(() {
      _resourceGroups = state.resourceGroups;
      Sort.byTitle(_resourceGroups);

      for (var group in _resourceGroups) {
        _resourcesMap[group.id] = state.resources
            .where((m) => m.resourceGroup == group.id)
            .toList();
        Sort.byTitle(_resourcesMap[group.id]!);
      }

      _coursesMap = {for (var course in state.courses) course.id: course};

      if (_resourceGroups.isNotEmpty) {
        _selectedGroupId = _resourceGroups.first.id;
      }

      isLoading = false;
    });
  }

  Widget _buildResourceCard(BuildContext context, ResourceModel resource) {
    return MobileGestureDetector(
      onTap: () => _onEdit(resource),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ResourceTitleLabel(
                      title: resource.title,
                      userSettings: userSettings!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (resource.website.isNotEmpty) ...[
                    HeliumIconButton(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(resource.website),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: Icons.link_outlined,
                      tooltip: "Launch resource's website",
                      color: context.semanticColors.success,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!Responsive.isMobile(context)) ...[
                    HeliumIconButton(
                      onPressed: () => _onEdit(resource),
                      icon: Icons.edit_outlined,
                    ),
                    const SizedBox(width: 8),
                  ],
                  HeliumIconButton(
                    onPressed: () {
                      showConfirmDeleteDialog(
                        parentContext: context,
                        item: resource,
                        onDelete: (m) {
                          context.read<ResourceBloc>().add(
                            DeleteResourceEvent(
                              origin: EventOrigin.screen,
                              resourceGroupId: m.resourceGroup,
                              resourceId: m.id,
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
                    PillBadge(text: ResourceConstants.status[resource.status]),
                    const SizedBox(width: 8),
                    if (ResourceConstants.status[resource.status] !=
                        ResourceConstants.condition[resource.condition])
                      PillBadge(
                        text: ResourceConstants.condition[resource.condition],
                      ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (resource.price != null && resource.price!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      resource.price!,
                      style: AppStyles.headingText(context),
                    ),
                  ],
                ],
              ),

              if (resource.courses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resource.courses.map((courseId) {
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

              if (resource.details != null && resource.details!.isNotEmpty) ...[
                const Divider(),

                const SizedBox(height: 12),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 50),
                  child: Html(
                    data: resource.details!,
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(
                          AppStyles.standardBodyText(context).fontSize!,
                        ),
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        maxLines: 2,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(ResourceModel resource) {
    showResourceAdd(
      context,
      resourceGroupId: _selectedGroupId!,
      resourceId: resource.id,
      isEdit: true,
    );
  }
}
