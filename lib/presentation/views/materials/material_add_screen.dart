// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/data/datasources/course_remote_data_source.dart';
import 'package:helium_mobile/data/models/planner/course_model.dart';
import 'package:helium_mobile/data/models/planner/material_group_response_model.dart';
import 'package:helium_mobile/data/models/planner/material_model.dart';
import 'package:helium_mobile/data/models/planner/material_request_model.dart';
import 'package:helium_mobile/data/repositories/course_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_event.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_state.dart'
    as course_state;
import 'package:helium_mobile/presentation/bloc/materialBloc/material_bloc.dart';
import 'package:helium_mobile/presentation/bloc/materialBloc/material_event.dart';
import 'package:helium_mobile/presentation/bloc/materialBloc/material_state.dart'
    as material_state;
import 'package:helium_mobile/presentation/widgets/custom_class_textfield.dart';
import 'package:helium_mobile/presentation/widgets/custom_text_button.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_enums.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_text_style.dart';

class MaterialsAddScreen extends StatefulWidget {
  final MaterialGroupResponseModel materialGroup;
  final List<Map<String, dynamic>> courses;
  final MaterialModel? existingMaterial; // Add this for editing

  const MaterialsAddScreen({
    super.key,
    required this.materialGroup,
    this.courses = const [],
    this.existingMaterial, // Add this parameter
  });

  @override
  State<MaterialsAddScreen> createState() => _MaterialsAddScreenState();
}

class _MaterialsAddScreenState extends State<MaterialsAddScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  List<int> selectedCourseIds = [];
  int? selectedStatus;
  int? selectedCondition;

  // Courses fetched from API
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing existing material
    if (widget.existingMaterial != null) {
      final material = widget.existingMaterial!;
      _titleController.text = material.title;
      _websiteController.text = material.website ?? '';
      _priceController.text = material.price ?? '';
      _detailsController.text = material.details ?? '';
      selectedStatus = material.status;
      selectedCondition = material.condition;
      if (material.courses != null && material.courses!.isNotEmpty) {
        selectedCourseIds = List<int>.from(material.courses!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _priceController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitMaterial(BuildContext context) {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter material title'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    // Create request
    final request = MaterialRequestModel(
      title: _titleController.text.trim(),
      status: selectedStatus,
      condition: selectedCondition,
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      price: _priceController.text.trim().isEmpty
          ? null
          : _priceController.text.trim(),
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      materialGroup: widget.materialGroup.id,
      courses: selectedCourseIds.isNotEmpty ? selectedCourseIds : null,
    );

    // Dispatch create or update event
    if (widget.existingMaterial != null) {
      // Update existing material
      BlocProvider.of<MaterialBloc>(context).add(
        UpdateMaterialEvent(
          groupId: widget.materialGroup.id,
          materialId: widget.existingMaterial!.id,
          request: request,
        ),
      );
    } else {
      // Create new material
      BlocProvider.of<MaterialBloc>(
        context,
      ).add(CreateMaterialEvent(request: request));
    }
  }

  List<CourseModel> _courseOptions() {
    if (_courses.isNotEmpty) return _courses;
    return widget.courses
        .map<CourseModel>(
          (c) => CourseModel(
            id: (c['id'] ?? 0) as int,
            title: (c['title'] ?? '') as String,
            room: '',
            credits: '0.00',
            color: '#cabdbf',
            website: '',
            isOnline: false,
            currentGrade: '-1.0000',
            trend: null,
            teacherName: '',
            teacherEmail: '',
            startDate: '',
            endDate: '',
            schedules: const [],
            courseGroup: 0,
            numDays: 0,
            numDaysCompleted: 0,
            hasWeightedGrading: false,
            numHomework: 0,
            numHomeworkCompleted: 0,
            numHomeworkGraded: 0,
          ),
        )
        .toList();
  }

  String _courseTitleById(int id) {
    final courses = _courseOptions();
    final match = courses.where((c) => c.id == id);
    return match.isNotEmpty ? match.first.title : 'Unknown';
  }

  Color _courseColorById(int id) {
    final courses = _courseOptions();
    final match = courses.where((c) => c.id == id);
    return match.isNotEmpty ? hexToColor(match.first.color) : whiteColor;
  }

  Future<void> _openCoursePicker() async {
    final options = _courseOptions();
    if (options.isEmpty) return;

    final Set<int> tempSelected = selectedCourseIds.toSet();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: whiteColor,
          title: Text(
            '',
            style: AppTextStyle.cTextStyle.copyWith(
              color: blackColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, localSetState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final course = options[index];
                    final checked = tempSelected.contains(course.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (val) {
                        localSetState(() {
                          if (val == true) {
                            tempSelected.add(course.id);
                          } else {
                            tempSelected.remove(course.id);
                          }
                        });
                      },
                      activeColor: primaryColor,
                      title: Text(
                        course.title,
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: AppTextStyle.eTextStyle.copyWith(color: textColor),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedCourseIds = tempSelected.toList();
                });
                Navigator.pop(dialogCtx);
              },
              child: Text(
                'Confirm',
                style: AppTextStyle.eTextStyle.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MaterialBloc, material_state.MaterialState>(
      listener: (context, state) {
        if (state is material_state.MaterialCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Material created successfully!'),
              backgroundColor: greenColor,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else if (state is material_state.MaterialCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: redColor),
          );
        } else if (state is material_state.MaterialUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Material updated successfully!'),
              backgroundColor: greenColor,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else if (state is material_state.MaterialUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: redColor),
          );
        }
      },
      child: BlocProvider<CourseBloc>(
        create: (context) => CourseBloc(
          courseRepository: CourseRepositoryImpl(
            remoteDataSource: CourseRemoteDataSourceImpl(
              dioClient: DioClient(),
            ),
          ),
        )..add(FetchCoursesEvent()),
        child: BlocListener<CourseBloc, course_state.CourseState>(
          listener: (context, state) {
            if (state is course_state.CourseLoaded) {
              setState(() {
                _courses = state.courses;
              });
            } else if (state is course_state.CourseError) {
              // Fallback to provided courses if API fails
              // Show a non-blocking snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: redColor,
                ),
              );
            }
          },
          child: _buildScaffold(context),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: softGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 12.h),
                width: double.infinity,
                decoration: BoxDecoration(color: whiteColor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.keyboard_arrow_left, color: blackColor),
                    ),
                    Text(
                      widget.existingMaterial != null
                          ? 'Edit Material'
                          : 'Add Material',
                      style: AppTextStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.import_contacts, color: transparentColor),
                  ],
                ),
              ),
              SizedBox(height: 22.v),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    CustomClassTextField(
                      text: '',
                      controller: _titleController,
                    ),
                    SizedBox(height: 14.v),
                    Text(
                      'Classes',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: blackColor.withValues(alpha: 0.3),
                        ),
                        color: whiteColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedCourseIds.isEmpty)
                            Text(
                              (_courses.isEmpty && widget.courses.isEmpty)
                                  ? 'No classes available'
                                  : '',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: -8,
                              children: selectedCourseIds.map((id) {
                                return Chip(
                                  backgroundColor: _courseColorById(id),
                                  deleteIconColor: whiteColor,
                                  label: Text(
                                    _courseTitleById(id),
                                    style: AppTextStyle.eTextStyle.copyWith(
                                      color: whiteColor,
                                    ),
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      selectedCourseIds.remove(id);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          SizedBox(height: 8.v),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AbsorbPointer(
                              absorbing: _courseOptions().isEmpty,
                              child: Opacity(
                                opacity: _courseOptions().isEmpty ? 0.5 : 1,
                                child: TextButton.icon(
                                  onPressed: () => _openCoursePicker(),
                                  icon: Icon(Icons.add, color: primaryColor),
                                  label: Text(
                                    'Select classes',
                                    style: AppTextStyle.eTextStyle.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.v),
                    Text(
                      'Status',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: blackColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButton<int>(
                        icon: Icon(Icons.keyboard_arrow_down),
                        dropdownColor: whiteColor,
                        isExpanded: true,
                        underline: SizedBox(),
                        hint: Text(
                          '',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.5),
                          ),
                        ),
                        value: selectedStatus,
                        items: materialStatus.asMap().entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 14.v),
                    Text(
                      'Condition',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: blackColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButton<int>(
                        icon: Icon(Icons.keyboard_arrow_down),
                        dropdownColor: whiteColor,
                        isExpanded: true,
                        underline: SizedBox(),
                        hint: Text(
                          '',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.5),
                          ),
                        ),
                        value: selectedCondition,
                        items: materialCondition.asMap().entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCondition = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 14.v),
                    Text(
                      'Website',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    CustomClassTextField(
                      text: '',
                      controller: _websiteController,
                    ),
                    SizedBox(height: 14.v),
                    Text(
                      'Price',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    CustomClassTextField(
                      text: '',
                      controller: _priceController,
                    ),
                    SizedBox(height: 14.v),
                    Text(
                      'Details',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: blackColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 9.v),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.adaptSize),
                        border: Border.all(color: blackColor.withValues(alpha: 0.3)),
                      ),
                      child: TextFormField(
                        controller: _detailsController,
                        maxLines: 8,
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '',
                          hintStyle: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 44.v),
                    BlocBuilder<MaterialBloc, material_state.MaterialState>(
                      builder: (context, state) {
                        final isCreating =
                            state is material_state.MaterialCreating;

                        return CustomTextButton(
                          buttonText: 'Save',
                          isLoading: isCreating,
                          onPressed: () => _submitMaterial(context),
                        );
                      },
                    ),
                    SizedBox(height: 44.v),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
