// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/course_remote_data_source.dart';
import 'package:heliumedu/data/datasources/material_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/course_model.dart';
import 'package:heliumedu/data/models/planner/material_group_request_model.dart';
import 'package:heliumedu/data/models/planner/material_group_response_model.dart';
import 'package:heliumedu/data/models/planner/material_model.dart';
import 'package:heliumedu/data/repositories/course_repository_impl.dart';
import 'package:heliumedu/data/repositories/material_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart'
    as course_state;
import 'package:heliumedu/presentation/bloc/materialBloc/material_bloc.dart';
import 'package:heliumedu/presentation/bloc/materialBloc/material_event.dart';
import 'package:heliumedu/presentation/bloc/materialBloc/material_state.dart'
    as material_state;
import 'package:heliumedu/presentation/widgets/custom_class_textfield.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  bool isHide = false;
  final TextEditingController _titleController = TextEditingController();
  List<MaterialGroupResponseModel> _materialGroups = [];
  List<MaterialModel> _allMaterials = [];
  List<MaterialModel> _filteredMaterials = [];
  MaterialGroupResponseModel? _selectedGroup;
  Map<int, CourseModel> _coursesMap = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Helper method to filter materials based on selected group
  void _filterMaterials() {
    if (_selectedGroup == null) {
      // Show all materials when no group is selected
      _filteredMaterials = List.from(_allMaterials);
    } else {
      // Filter materials by selected group
      _filteredMaterials = _allMaterials
          .where((material) => material.materialGroup == _selectedGroup!.id)
          .toList();
    }
  }

  // Helper method to launch URL
  Future<void> _launchURL(String url) async {
    try {
      // Clean and format URL
      String cleanUrl = url.trim();

      // Add https:// if no protocol is specified
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);

      // Try to launch the URL
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL: $url'),
            backgroundColor: redColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: ${e.toString()}'),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MaterialBloc(
                  materialRepository: MaterialRepositoryImpl(
                    remoteDataSource: MaterialRemoteDataSourceImpl(
                      dioClient: DioClient(),
                    ),
                  ),
                )
                ..add(FetchMaterialGroupsEvent())
                ..add(FetchAllMaterialsEvent()),
        ),
        BlocProvider(
          create: (context) => CourseBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchCoursesEvent()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MaterialBloc, material_state.MaterialState>(
            listener: (context, state) {
              if (state is material_state.MaterialGroupsLoaded) {
                setState(() {
                  _materialGroups = state.materialGroups;
                  // Ensure selected group remains valid; otherwise reset
                  if (_selectedGroup != null) {
                    final stillExists = _materialGroups.any(
                      (g) => g.id == _selectedGroup!.id,
                    );
                    if (!stillExists) {
                      _selectedGroup = null;
                    }
                  }
                  // If no selection yet, default to most recently created group (highest id)
                  if (_selectedGroup == null && _materialGroups.isNotEmpty) {
                    _materialGroups.sort((a, b) => b.id.compareTo(a.id));
                    _selectedGroup = _materialGroups.first;
                  }
                  // Apply filtering based on selected group
                  _filterMaterials();
                });
              } else if (state is material_state.MaterialGroupsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              } else if (state is material_state.MaterialGroupCreated) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material group created successfully!'),
                    backgroundColor: greenColor,
                  ),
                );
              } else if (state is material_state.MaterialGroupCreateError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              } else if (state is material_state.MaterialGroupDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material group deleted successfully!'),
                    backgroundColor: greenColor,
                  ),
                );
              } else if (state is material_state.MaterialGroupDeleteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              } else if (state is material_state.MaterialGroupUpdated) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material group updated successfully!'),
                    backgroundColor: greenColor,
                  ),
                );
              } else if (state is material_state.MaterialGroupUpdateError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              } else if (state is material_state.MaterialsLoaded) {
                setState(() {
                  _allMaterials = state.materials;
                  _filterMaterials();
                });
              } else if (state is material_state.MaterialsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              } else if (state is material_state.MaterialDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material deleted successfully!'),
                    backgroundColor: greenColor,
                  ),
                );
                // Refresh all materials after deletion
                BlocProvider.of<MaterialBloc>(
                  context,
                ).add(FetchAllMaterialsEvent());
              } else if (state is material_state.MaterialDeleteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              }
            },
          ),
          BlocListener<CourseBloc, course_state.CourseState>(
            listener: (context, state) {
              if (state is course_state.CourseLoaded) {
                setState(() {
                  // Create a map for quick lookup
                  _coursesMap = {
                    for (var course in state.courses) course.id: course,
                  };
                });
              }
            },
          ),
        ],
        child: Builder(builder: (context) => _buildScaffold(context)),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: softGrey,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
              decoration: BoxDecoration(
                color: whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: blackColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.settingScreen);
                    },
                    child: Icon(
                      Icons.settings_outlined,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  Text(
                    'Materials',
                    style: AppTextStyle.bTextStyle.copyWith(color: textColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.notificationScreen,
                      );
                    },
                    child: Icon(Icons.notifications, color: primaryColor),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.v),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: blackColor.withOpacity(0.6),
                        ),
                        dropdownColor: whiteColor,
                        isExpanded: true,
                        underline: SizedBox(),
                        hint: Text(
                          "Loading groups ...",
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withOpacity(0.5),
                          ),
                        ),
                        value: _selectedGroup?.id,
                        items:
                            _materialGroups.asMap().entries.map((entry) {
                              MaterialGroupResponseModel group = entry.value;

                              return DropdownMenuItem(
                                value: group.id,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.title,
                                        style: AppTextStyle.eTextStyle.copyWith(
                                          color: blackColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Edit material group
                                        _showAddGroupDialog(
                                          context,
                                          existingGroup: group,
                                        );
                                      },
                                      child: Icon(
                                        Icons.edit,
                                        color: primaryColor,
                                        size: 20.adaptSize,
                                      ),
                                    ),
                                    SizedBox(width: 8.h),
                                    GestureDetector(
                                      onTap: () {
                                        // Delete material group
                                        _showDeleteConfirmDialog(
                                          context,
                                          group,
                                        );
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        color: redColor,
                                        size: 20.adaptSize,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList()..add(
                              DropdownMenuItem<int>(
                                value: null,
                                enabled: false,
                                child: GestureDetector(
                                  onTap: () {
                                    // Show add group dialog
                                    _showAddGroupDialog(context);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.h,
                                      vertical: 8.v,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        6.adaptSize,
                                      ),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: primaryColor,
                                          size: 18.adaptSize,
                                        ),
                                        SizedBox(width: 6.h),
                                        Text(
                                          'Add New Group',
                                          style: AppTextStyle.eTextStyle
                                              .copyWith(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        onChanged: (value) {
                          // Don't handle null values (add button clicks)
                          if (value == null) return;

                          // Show all materials when no group is selected
                          if (value == -1) {
                            setState(() {
                              _selectedGroup = null;
                              _filterMaterials();
                            });
                            return;
                          }
                          // Find selected group by id and filter materials
                          final selected = _materialGroups.firstWhere(
                            (group) => group.id == value,
                            orElse: () => _materialGroups.first,
                          );
                          setState(() {
                            _selectedGroup = selected;
                            _filterMaterials();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ), // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<MaterialBloc, material_state.MaterialState>(
                      builder: (context, state) {
                        if (state is material_state.MaterialsLoading) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.h),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(whiteColor),
                                color: primaryColor,
                              ),
                            ),
                          );
                        }

                        if (_filteredMaterials.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.h),
                              child: Text(
                                _selectedGroup == null
                                    ? 'No materials found'
                                    : 'No materials found in this group',
                                style: AppTextStyle.bTextStyle.copyWith(
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: _filteredMaterials.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final material = _filteredMaterials[index];
                            return Container(
                              padding: EdgeInsets.all(16.h),
                              decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(
                                  12.adaptSize,
                                ),
                                border: Border.all(
                                  color: blackColor.withOpacity(0.08),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: blackColor.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Price Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          material.title,
                                          style: AppTextStyle.aTextStyle
                                              .copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),

                                      GestureDetector(
                                        onTap: () async {
                                          // Navigate to edit material screen
                                          final result =
                                              await Navigator.pushNamed(
                                                context,
                                                AppRoutes.addMaterialScreen,
                                                arguments: {
                                                  'materialGroup':
                                                      _selectedGroup!,
                                                  'courses':
                                                      <Map<String, dynamic>>[],
                                                  'existingMaterial': material,
                                                },
                                              );

                                          // Refresh materials if material was updated
                                          if (result == true) {
                                            BlocProvider.of<MaterialBloc>(
                                              context,
                                            ).add(FetchAllMaterialsEvent());
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(6.adaptSize),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.adaptSize,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 18.adaptSize,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.h),
                                      GestureDetector(
                                        onTap: () {
                                          _showDeleteMaterialDialog(
                                            context,
                                            material,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(6.adaptSize),
                                          decoration: BoxDecoration(
                                            color: redColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6.adaptSize,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 18.adaptSize,
                                            color: redColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12.v),

                                  // Status and Price Row
                                  Row(
                                    children: [
                                      if (material.status != null) ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.h,
                                            vertical: 4.v,
                                          ),
                                          decoration: BoxDecoration(
                                            color: greenColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6.adaptSize,
                                            ),
                                            border: Border.all(
                                              color: greenColor.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            material.statusDisplay,
                                            style: AppTextStyle.cTextStyle
                                                .copyWith(
                                                  color: greenColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 8.h),
                                      ],
                                      if (material.condition != null)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.h,
                                            vertical: 4.v,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.adaptSize,
                                            ),
                                            border: Border.all(
                                              color: primaryColor.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            material.conditionDisplay,
                                            style: AppTextStyle.cTextStyle
                                                .copyWith(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                      Spacer(),
                                      if (material.price != null &&
                                          material.price!.isNotEmpty) ...[
                                        SizedBox(width: 12.h),
                                        Text(
                                          material.price!,
                                          style: AppTextStyle.aTextStyle
                                              .copyWith(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Display course information if available
                                  if (material.courses != null &&
                                      material.courses!.isNotEmpty) ...[
                                    SizedBox(height: 12.v),
                                    Wrap(
                                      spacing: 8.h,
                                      runSpacing: 8.v,
                                      children: material.courses!.map((
                                        courseId,
                                      ) {
                                        final course = _coursesMap[courseId];
                                        if (course == null) {
                                          return SizedBox.shrink();
                                        }

                                        // Parse color from hex string
                                        Color courseColor;
                                        try {
                                          final colorHex = course.color
                                              .replaceAll('#', '');
                                          courseColor = Color(
                                            int.parse('ff$colorHex', radix: 16),
                                          );
                                        } catch (e) {
                                          courseColor = primaryColor;
                                        }

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: courseColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4.adaptSize,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.h,
                                            vertical: 4.v,
                                          ),
                                          child: Text(
                                            course.title,
                                            style: AppTextStyle.cTextStyle
                                                .copyWith(
                                                  color: courseColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  if (material.details != null &&
                                      material.details!.isNotEmpty) ...[
                                    SizedBox(height: 12.v),
                                    Text(
                                      material.details!
                                          .replaceAll(RegExp(r'<[^>]*>'), '')
                                          .trim(),
                                      style: AppTextStyle.cTextStyle.copyWith(
                                        color: textColor.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],

                                  if (material.website != null &&
                                      material.website!.isNotEmpty) ...[
                                    SizedBox(height: 12.v),
                                    GestureDetector(
                                      onTap: () =>
                                          _launchURL(material.website!),
                                      child: Text(
                                        'Website: ${material.website}',
                                        style: AppTextStyle.cTextStyle.copyWith(
                                          color: primaryColor,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return SizedBox(height: 12.v);
                          },
                        );
                      },
                    ),

                    SizedBox(height: 24.v),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 105.h),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          shape: CircleBorder(),
          onPressed: () async {
            if (_selectedGroup != null) {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.addMaterialScreen,
                arguments: {
                  'materialGroup': _selectedGroup!,
                  'courses': <Map<String, dynamic>>[],
                },
              );

              // Refresh materials if a material was created
              if (result == true) {
                BlocProvider.of<MaterialBloc>(
                  context,
                ).add(FetchAllMaterialsEvent());
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please select a material group first',
                    style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                  ),
                  backgroundColor: redColor,
                ),
              );
            }
          },
          backgroundColor: primaryColor,
          elevation: 0,
          child: Icon(Icons.add, color: whiteColor, size: 28.adaptSize),
        ),
      ),
    );
  }

  void _showAddGroupDialog(
    BuildContext context, {
    MaterialGroupResponseModel? existingGroup,
  }) {
    final isEdit = existingGroup != null;

    // Pre-fill form if editing
    if (isEdit) {
      _titleController.text = existingGroup.title;
      setState(() {
        isHide = !existingGroup.shownOnCalendar;
      });
    } else {
      _titleController.clear();
      setState(() {
        isHide = false;
      });
    }

    // Capture the bloc before showing dialog
    final materialBloc = BlocProvider.of<MaterialBloc>(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String? errorMessage;

        return BlocProvider.value(
          value: materialBloc,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return BlocListener<MaterialBloc, material_state.MaterialState>(
                listener: (context, state) {
                  if (state is material_state.MaterialGroupCreateError ||
                      state is material_state.MaterialGroupUpdateError) {
                    setDialogState(() {
                      errorMessage =
                          state is material_state.MaterialGroupCreateError
                          ? state.message
                          : (state as material_state.MaterialGroupUpdateError)
                                .message;
                    });
                  } else if (state is material_state.MaterialGroupCreated ||
                      state is material_state.MaterialGroupUpdated) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20.h),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 2.v),
                        Center(
                          child: Text(
                            isEdit ? 'Edit Group' : 'Add Group',
                            style: AppTextStyle.aTextStyle.copyWith(
                              color: blackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 33.v),
                        // Error message display
                        if (errorMessage != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.h,
                              vertical: 10.v,
                            ),
                            decoration: BoxDecoration(
                              color: redColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.adaptSize),
                              border: Border.all(
                                color: redColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: redColor,
                                  size: 20.adaptSize,
                                ),
                                SizedBox(width: 8.h),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: AppTextStyle.cTextStyle.copyWith(
                                      color: redColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      errorMessage = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: redColor,
                                    size: 18.adaptSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.v),
                        ],
                        Text(
                          'Title',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        CustomClassTextField(
                          text: '',
                          controller: _titleController,
                        ),
                        SizedBox(height: 20.v),
                        Row(
                          children: [
                            Checkbox(
                              value: isHide,
                              onChanged: (bool? newValue) {
                                setDialogState(() {
                                  isHide = newValue ?? false;
                                  errorMessage =
                                      null; // Clear error when user interacts
                                });
                              },
                              activeColor: primaryColor,
                            ),
                            Expanded(
                              child: Text(
                                "Hide this group's materials from Calendar",
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.v),
                        BlocBuilder<MaterialBloc, material_state.MaterialState>(
                          builder: (context, state) {
                            final isLoading =
                                state is material_state.MaterialGroupCreating ||
                                state is material_state.MaterialGroupUpdating;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => Navigator.pop(dialogContext),
                                  child: Text(
                                    'Cancel',
                                    style: AppTextStyle.iTextStyle.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.h),
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          // Clear previous error
                                          setDialogState(() {
                                            errorMessage = null;
                                          });

                                          if (_titleController.text
                                              .trim()
                                              .isEmpty) {
                                            setDialogState(() {
                                              errorMessage =
                                                  'Please enter a group name';
                                            });
                                            return;
                                          }

                                          // Create material group request
                                          final request =
                                              MaterialGroupRequestModel(
                                                title: _titleController.text
                                                    .trim(),
                                                shownOnCalendar: !isHide,
                                              );

                                          // Dispatch create or update event
                                          if (isEdit) {
                                            BlocProvider.of<MaterialBloc>(
                                              context,
                                            ).add(
                                              UpdateMaterialGroupEvent(
                                                groupId: existingGroup.id,
                                                request: request,
                                              ),
                                            );
                                          } else {
                                            BlocProvider.of<MaterialBloc>(
                                              context,
                                            ).add(
                                              CreateMaterialGroupEvent(
                                                request: request,
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        9.adaptSize,
                                      ),
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 16.adaptSize,
                                          height: 16.adaptSize,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    whiteColor,
                                                  ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Save',
                                          style: AppTextStyle.iTextStyle
                                              .copyWith(color: whiteColor),
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    MaterialGroupResponseModel group,
  ) {
    final materialBloc = BlocProvider.of<MaterialBloc>(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: materialBloc,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
            title: Text(
              'Delete Material Group',
              style: AppTextStyle.aTextStyle.copyWith(color: blackColor),
            ),
            content: Text(
              'Are you sure you want to delete "${group.title}"?',
              style: AppTextStyle.cTextStyle.copyWith(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: AppTextStyle.iTextStyle.copyWith(color: textColor),
                ),
              ),
              BlocBuilder<MaterialBloc, material_state.MaterialState>(
                builder: (context, state) {
                  final isDeleting =
                      state is material_state.MaterialGroupDeleting;

                  return ElevatedButton(
                    onPressed: isDeleting
                        ? null
                        : () {
                            BlocProvider.of<MaterialBloc>(
                              context,
                            ).add(DeleteMaterialGroupEvent(groupId: group.id));
                            Navigator.pop(dialogContext);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9.adaptSize),
                      ),
                    ),
                    child: isDeleting
                        ? SizedBox(
                            width: 16.adaptSize,
                            height: 16.adaptSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                whiteColor,
                              ),
                            ),
                          )
                        : Text(
                            'Delete',
                            style: AppTextStyle.iTextStyle.copyWith(
                              color: whiteColor,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteMaterialDialog(BuildContext context, MaterialModel material) {
    final materialBloc = BlocProvider.of<MaterialBloc>(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: materialBloc,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
            title: Text(
              'Delete Material',
              style: AppTextStyle.aTextStyle.copyWith(color: blackColor),
            ),
            content: Text(
              'Are you sure you want to delete "${material.title}"?',
              style: AppTextStyle.cTextStyle.copyWith(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: AppTextStyle.iTextStyle.copyWith(color: textColor),
                ),
              ),
              BlocBuilder<MaterialBloc, material_state.MaterialState>(
                builder: (context, state) {
                  final isDeleting = state is material_state.MaterialDeleting;

                  return ElevatedButton(
                    onPressed: isDeleting
                        ? null
                        : () {
                            if (_selectedGroup == null) {
                              Navigator.pop(dialogContext);
                              return;
                            }
                            BlocProvider.of<MaterialBloc>(context).add(
                              DeleteMaterialEvent(
                                groupId: material.materialGroup,
                                materialId: material.id,
                              ),
                            );
                            Navigator.pop(dialogContext);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9.adaptSize),
                      ),
                    ),
                    child: isDeleting
                        ? SizedBox(
                            width: 16.adaptSize,
                            height: 16.adaptSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                whiteColor,
                              ),
                            ),
                          )
                        : Text(
                            'Delete',
                            style: AppTextStyle.iTextStyle.copyWith(
                              color: whiteColor,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
