// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/note_repository_impl.dart';
import 'package:heliumapp/data/repositories/resource_repository_impl.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/note_remote_data_source.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/core/views/deep_link_mixin.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/features/resources/constants/resource_constants.dart';
import 'package:heliumapp/presentation/features/resources/dialogs/resource_group_dialog.dart';
import 'package:heliumapp/presentation/features/resources/views/resource_add_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/group_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/notes_viewer.dart';
import 'package:heliumapp/presentation/ui/components/pill_badge.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_card_grid.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/quill_helpers.dart';
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
            noteRepository: NoteRepositoryImpl(
              remoteDataSource: NoteRemoteDataSourceImpl(dioClient: _dioClient),
            ),
          ),
        ),
        BlocProvider(
          create: ProviderHelpers().createNoteBloc(),
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
    extends BasePageScreenState<_ResourcesProvidedScreen>
    with DeepLinkMixin {
  @override
  String get screenTitle => 'Resources';

  @override
  bool get enablePrint => true;

  @override
  String get routePath => AppRoute.resourcesScreen;

  @override
  VoidCallback get actionButtonCallback => () {
    if (_selectedGroupId != null) {
      openWithGuard(
        '${DeepLinkParam.id}:new',
        () => showResourceAdd(
          context,
          resourceGroupId: _selectedGroupId!,
          isEdit: false,
        ),
      );
    } else {
      showSnackBar(context, 'Create a group first', type: SnackType.info);
    }
  };

  @override
  bool get showActionButton => _resourceGroups.isNotEmpty;

  List<ResourceGroupModel> _resourceGroups = [];
  final Map<int, List<ResourceModel>> _resourcesMap = {};
  Map<int, CourseModel> _coursesMap = {};
  Map<int, NoteModel> _notesMap = {}; // resourceId -> Note
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
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdated) {
            setState(() {
              userSettings = state.user.settings;
            });
          }
        },
      ),
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NoteCreated) {
            final resourceId = state.note.resources.firstOrNull;
            if (resourceId != null) {
              setState(() => _upsertNoteForResource(resourceId, state.note));
            }
          } else if (state is NoteUpdated) {
            final resourceId = state.note.resources.firstOrNull;
            if (resourceId != null) {
              setState(() => _upsertNoteForResource(resourceId, state.note));
            }
          } else if (state is NoteDeleted) {
            setState(() {
              _notesMap.removeWhere((_, note) => note.id == state.noteId);
            });
          }
        },
      ),
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
              _notesMap.remove(state.id);
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GroupDropdown(
          groups: _resourceGroups,
          initialSelection: _resourceGroups.firstWhereOrNull(
            (g) => g.id == _selectedGroupId,
          ),
          isReadOnly: isCapturing,
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
            source: 'resources_screen',
            onReload: () {
              context.read<ResourceBloc>().add(
                FetchResourcesScreenDataEvent(origin: EventOrigin.screen, forceRefresh: true),
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

  @override
  bool handleRouteEntityParams(Map<String, String> queryParams) {
    final idParam = queryParams[DeepLinkParam.id];
    if (idParam == null) return false;

    final parsed = DeepLinkParam.parseId(idParam);
    final tabValue = int.tryParse(queryParams[DeepLinkParam.tab] ?? '') ?? 1;
    final initialStep = (tabValue - 1).clamp(0, 2);

    if (parsed.isNew) {
      if (_selectedGroupId == null) return false;
      return openFromDeepLink('${DeepLinkParam.id}:new', () {
        return showResourceAdd(
          context,
          resourceGroupId: _selectedGroupId!,
          isEdit: false,
          initialStep: initialStep,
        );
      });
    }

    if (parsed.id != null) {
      ResourceModel? resource;
      for (final resources in _resourcesMap.values) {
        resource = resources.firstWhereOrNull((r) => r.id == parsed.id);
        if (resource != null) break;
      }
      if (resource == null) return false;
      return openFromDeepLink('${DeepLinkParam.id}:${parsed.id}', () {
        return showResourceAdd(
          context,
          resourceGroupId: resource!.resourceGroup,
          resourceId: resource.id,
          isEdit: true,
          initialStep: initialStep,
        );
      });
    }

    return false;
  }

  void _upsertNoteForResource(int resourceId, NoteModel note) {
    _notesMap[resourceId] = note;
  }

  Widget _buildResourcesList() {
    if (_selectedGroupId == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) => ResponsiveCardGrid<ResourceModel>(
        shrinkWrap: isCapturing,
        printPageBreakAfterRow: true,
        items: _resourcesMap[_selectedGroupId]!,
        itemBuilder: (context, resource) {
          try {
            return _buildResourceCard(context, resource);
          } catch (e, st) {
            ErrorHelpers.logAndReport(
              'Failed to render resource card ${resource.id}',
              e,
              st,
              hints: {'resource_id': resource.id},
            );
            return const SizedBox.shrink();
          }
        },
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

      _notesMap = {};
      for (final note in state.notes) {
        if (note.resources.isNotEmpty) {
          _upsertNoteForResource(note.resources.first, note);
        }
      }

      if (_resourceGroups.isNotEmpty) {
        _selectedGroupId = _resourceGroups.first.id;
      }

      isLoading = false;
    });

    openFromQueryParams();
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
                    PrintHidden(
                      child: HeliumIconButton(
                        onPressed: () {
                          launchUrl(Uri.parse(resource.website));
                        },
                        icon: Icons.launch_outlined,
                        tooltip: "Launch resource's website",
                        color: context.semanticColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!Responsive.isMobile(context)) ...[
                    PrintHidden(
                      child: HeliumIconButton(
                        onPressed: () => _onEdit(resource),
                        icon: Icons.edit_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PrintHidden(
                    child: HeliumIconButton(
                      onPressed: () {
                        showConfirmDeleteDialog(
                          parentContext: context,
                          item: resource,
                          additionalWarning:
                              'Its associated attachments and note will also be deleted.',
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
                      compact: true,
                    );
                  }).toList(),
                ),
              ],

              if (_notesMap[resource.id] case final note?
                  when !isNotesEmpty(note.content)) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                NotesViewer(notes: note.content),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(ResourceModel resource) {
    openWithGuard(
      '${DeepLinkParam.id}:${resource.id}',
      () => showResourceAdd(
        context,
        resourceGroupId: resource.resourceGroup,
        resourceId: resource.id,
        isEdit: true,
      ),
    );
  }

}
