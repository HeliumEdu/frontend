import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
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
import 'package:heliumapp/utils/screen_dropdown_filter_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ResourcesProvidedScreen();
}

class _ResourcesProvidedScreen extends StatefulWidget {
  const _ResourcesProvidedScreen();

  @override
  State<_ResourcesProvidedScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState
    extends BasePageScreenState<_ResourcesProvidedScreen>
    with DeepLinkMixin {
  static const int _showAllGroupId = -1;

  @override
  bool get enablePrint => true;

  @override
  String get routePath => AppRoute.resourcesScreen;

  @override
  VoidCallback get actionButtonCallback => () {
    if (_resourceGroups.isEmpty) {
      showSnackBar(context, 'Create a group first.', type: SnackType.info);
      return;
    }
    showResourceAdd(
      context,
      resourceGroupId: _selectedGroupId == _showAllGroupId
          ? null
          : _selectedGroupId,
      isEdit: false,
    );
  };

  @override
  bool get showActionButton => _resourceGroups.isNotEmpty;

  List<ResourceGroupModel> _resourceGroups = [];
  final Map<int, List<ResourceModel>> _resourcesMap = {};
  Map<int, CourseModel> _coursesMap = {};
  Map<int, NoteModel> _notesMap = {}; // resourceId -> Note
  int? _selectedGroupId;

  ResourceGroupModel get _showAllGroup => ResourceGroupModel(
    id: _showAllGroupId,
    title: 'Show All',
    shownOnCalendar: true,
  );

  @override
  void initState() {
    super.initState();

    DioClient().cacheService.addInactivityResumeListener(
      _resetSelectedGroupOnResume,
    );
    context.read<ResourceBloc>().add(
      FetchResourcesScreenDataEvent(origin: EventOrigin.screen),
    );
  }

  @override
  void dispose() {
    DioClient().cacheService.removeInactivityResumeListener(
      _resetSelectedGroupOnResume,
    );
    super.dispose();
  }

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (!mounted || settings == null) return settings;
      _restoreSelectedGroup(settings);
      return settings;
    });
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
          if (state is ResourcesError && state.origin == EventOrigin.screen) {
            setState(() { isLoading = false; screenError = state.message; });
          } else if (state is ResourcesScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is ResourceGroupCreated) {
            showSnackBar(context, 'Group created.');

            setState(() {
              _resourceGroups.add(state.resourceGroup);
              Sort.byTitle(_resourceGroups);
              _selectedGroupId = state.resourceGroup.id;
              _resourcesMap[_selectedGroupId!] = [];
            });
            _saveSelectedGroup();
          } else if (state is ResourceGroupUpdated) {
            // No snackbar on updates

            setState(() {
              final index = _resourceGroups.indexWhere(
                (g) => g.id == state.resourceGroup.id,
              );
              if (index == -1) return;
              _resourceGroups[index] = state.resourceGroup;
              Sort.byTitle(_resourceGroups);
            });
          } else if (state is ResourceGroupDeleted) {
            showSnackBar(context, 'Group deleted.');

            setState(() {
              _resourceGroups.removeWhere((g) => g.id == state.id);
              _resourcesMap.remove(state.id);
              if (_resourceGroups.isEmpty) {
                _selectedGroupId = null;
              } else if (_selectedGroupId != _showAllGroupId &&
                  !_resourceGroups.any((g) => g.id == _selectedGroupId)) {
                // Reset if selected group was deleted
                _selectedGroupId = _resourceGroups.first.id;
              }
            });
            _saveSelectedGroup();
          } else if (state is ResourceCreated) {
            setState(() {
              _resourcesMap
                  .putIfAbsent(state.resource.resourceGroup, () => [])
                  .add(state.resource);
              Sort.byTitle(_resourcesMap[state.resource.resourceGroup]!);
            });
          } else if (state is ResourceUpdated) {
            setState(() {
              for (final resources in _resourcesMap.values) {
                resources.removeWhere((m) => m.id == state.resource.id);
              }
              _resourcesMap
                  .putIfAbsent(state.resource.resourceGroup, () => [])
                  .add(state.resource);
              Sort.byTitle(_resourcesMap[state.resource.resourceGroup]!);
            });
          } else if (state is ResourceDeleted) {
            showSnackBar(context, 'Resource deleted.');

            setState(() {
              for (final resources in _resourcesMap.values) {
                resources.removeWhere((m) => m.id == state.id);
              }
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
          groups: _resourceGroups.isEmpty
              ? _resourceGroups
              : [_showAllGroup, ..._resourceGroups],
          initialSelection: _selectedGroupId == _showAllGroupId
              ? _showAllGroup
              : _resourceGroups.firstWhereOrNull(
                  (g) => g.id == _selectedGroupId,
                ),
          isReadOnly: isCapturing,
          isEditable: (g) => g.id != _showAllGroupId,
          onChanged: (value) {
            // The "+" button has a null value
            if (value == null) return;
            if (value.id == _selectedGroupId) return;

            setState(() {
              _selectedGroupId = value.id;
            });
            _saveSelectedGroup();
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
          return const Center(child: LoadingIndicator(expanded: false));
        }

        if (screenError != null) {
          return ErrorCard(
            message: screenError!,
            source: 'resources_screen',
            onReload: reloadPage,
          );
        }

        if (_resourceGroups.isEmpty) {
          return const EmptyCard(
            icon: Icons.book,
            title: "You haven't added any groups yet",
            message: 'Click "+ Add Group" to get started',
            expanded: false,
          );
        }

        if (_selectedGroupId == _showAllGroupId) {
          final hasAnyResources = _resourceGroups.any(
            (g) => _resourcesMap[g.id]?.isNotEmpty ?? false,
          );
          if (!hasAnyResources) {
            return const EmptyCard(
              icon: Icons.book,
              title: "You haven't added any resources yet",
              message: 'Click "+" to get started',
              expanded: false,
            );
          }
          return _buildGroupedResourcesList();
        }

        if (_selectedGroupId == null ||
            (_resourcesMap[_selectedGroupId]?.isEmpty ?? true)) {
          return const EmptyCard(
            icon: Icons.book,
            title: "You haven't added any resources yet",
            message: 'Click "+" to get started',
            expanded: false,
          );
        }

        return _buildResourcesList();
      },
    );
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
        maxCardWidth: Responsive.isDesktop(context) ? 430 : 390,
        shrinkWrap: isCapturing,
        printPageBreakAfterRow: true,
        items: _resourcesMap[_selectedGroupId]!,
        itemBuilder: (context, resource) =>
            _safeBuildResourceCard(context, resource),
      ),
    );
  }

  /// Renders every group that has at least one resource as its own labeled
  /// section, in place of the single-group flat list, for the "Show All"
  /// filter option.
  Widget _buildGroupedResourcesList() {
    final groupsWithResources = _resourceGroups
        .where((g) => _resourcesMap[g.id]?.isNotEmpty ?? false)
        .toList();

    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) => ListView.builder(
        shrinkWrap: isCapturing,
        physics: isCapturing ? const NeverScrollableScrollPhysics() : null,
        itemCount: groupsWithResources.length,
        itemBuilder: (context, index) {
          final group = groupsWithResources[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == groupsWithResources.length - 1 ? 0 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  style: AppStyles.featureText(context).copyWith(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      desktop: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ResponsiveCardGrid<ResourceModel>(
                  maxCardWidth: Responsive.isDesktop(context) ? 430 : 390,
                  shrinkWrap: true,
                  printPageBreakAfterRow: true,
                  items: _resourcesMap[group.id]!,
                  itemBuilder: (context, resource) =>
                      _safeBuildResourceCard(context, resource),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _safeBuildResourceCard(BuildContext context, ResourceModel resource) {
    try {
      return _buildResourceCard(context, resource);
    } catch (e, st) {
      ErrorHelpers.logAndReport(
        'Failed to render resource card ${resource.id}',
        e,
        st,
      );
      return const SizedBox.shrink();
    }
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
        final isValidSelection =
            _selectedGroupId == _showAllGroupId ||
            _resourceGroups.any((g) => g.id == _selectedGroupId);
        if (_selectedGroupId == null || !isValidSelection) {
          _selectedGroupId = _resourceGroups.first.id;
        }
      } else {
        _selectedGroupId = null;
      }

      isLoading = false;
      screenError = null;
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
                  if (resource.website != null) ...[
                    PrintHidden(
                      child: HeliumIconButton(
                        onPressed: () {
                          UrlHelpers.launchWebUrl(resource.website.toString());
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
                      child: Semantics(
                        label: 'Edit',
                        button: true,
                        child: HeliumIconButton(
                          onPressed: () => _onEdit(resource),
                          icon: Icons.edit_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PrintHidden(
                    child: Semantics(
                      label: 'Delete',
                      button: true,
                      child: HeliumIconButton(
                        onPressed: () {
                          showConfirmDeleteDialog(
                            parentContext: context,
                            item: resource,
                            label: resource.title,
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
    showResourceAdd(
      context,
      resourceGroupId: resource.resourceGroup,
      resourceId: resource.id,
      isEdit: true,
    );
  }

  void _saveSelectedGroup() {
    if (_selectedGroupId == null) return;

    ScreenDropdownFilterHelpers.save(
      ScreensDropdownFilterPrefKey.resourcesGroupId,
      _selectedGroupId!,
      userSettings,
    );
  }

  void _restoreSelectedGroup(UserSettingsModel settings) {
    final savedGroupId = ScreenDropdownFilterHelpers.restore(
      ScreensDropdownFilterPrefKey.resourcesGroupId,
      settings,
    );
    if (savedGroupId == null) return;

    setState(() {
      _selectedGroupId = savedGroupId;
    });
  }

  /// Fires on the same inactivity-resume threshold that makes the shell clear
  /// the saved selection — but a screen that's currently mounted (i.e. the
  /// user was sitting on it when they backgrounded/foregrounded) won't
  /// otherwise pick that up, since restoring only happens on mount.
  void _resetSelectedGroupOnResume() {
    if (!mounted || _resourceGroups.isEmpty) return;

    setState(() {
      _selectedGroupId = _resourceGroups.first.id;
    });
  }
}
