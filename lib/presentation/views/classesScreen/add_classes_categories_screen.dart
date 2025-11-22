// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/attachment_remote_data_source.dart';
import 'package:heliumedu/data/datasources/course_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/attachment_model.dart';
import 'package:heliumedu/data/models/planner/category_model.dart';
import 'package:heliumedu/data/models/planner/category_request_model.dart';
import 'package:heliumedu/data/repositories/attachment_repository_impl.dart';
import 'package:heliumedu/data/repositories/course_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart';
import 'package:heliumedu/presentation/views/settingScreen/feeds_and_external_calendars_settings_screen.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

import '../../../utils/custom_color_picker.dart';

class AddClassesCategoriesScreen extends StatefulWidget {
  final int courseId;
  final int courseGroupId;
  final bool isEdit;

  const AddClassesCategoriesScreen({
    super.key,
    required this.courseId,
    required this.courseGroupId,
    this.isEdit = false,
  });

  @override
  State<AddClassesCategoriesScreen> createState() =>
      _AddClassesCategoriesScreenState();
}

class _AddClassesCategoriesScreenState
    extends State<AddClassesCategoriesScreen> {
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryWeightController =
      TextEditingController();

  late CourseBloc _courseBloc;
  String? uploadedFileName;
  File? _selectedFile;
  bool _isSubmitting = false;
  List<AttachmentModel> _serverAttachments = [];
  Color selectedColor = const Color(0xFF16a765);

  @override
  void initState() {
    super.initState();
    _courseBloc = CourseBloc(
      courseRepository: CourseRepositoryImpl(
        remoteDataSource: CourseRemoteDataSourceImpl(dioClient: DioClient()),
      ),
    );
    _courseBloc.add(
      FetchCategoriesEvent(
        groupId: widget.courseGroupId,
        courseId: widget.courseId,
      ),
    );
    _refreshAttachments();
  }

  Future<void> _refreshAttachments() async {
    if (widget.courseId == null) return;
    try {
      final attachmentDataSource = AttachmentRemoteDataSourceImpl(
        dioClient: DioClient(),
      );
      final attachments = await attachmentDataSource.getAttachments();
      setState(() {
        _serverAttachments = attachments
            .where((a) => a.course == widget.courseId)
            .toList();
      });
    } catch (e) {
      // Non-blocking
      debugPrint('Failed to load attachments: $e');
    }
  }

  Future<void> _confirmDeleteAttachment(AttachmentModel attachment) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Attachment',
          style: AppTextStyle.cTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this attachment?',
          style: AppTextStyle.eTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyle.eTextStyle.copyWith(color: greyColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final attachmentDataSource = AttachmentRemoteDataSourceImpl(
                  dioClient: DioClient(),
                );
                await attachmentDataSource.deleteAttachment(attachment.id);
                await _refreshAttachments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Attachment deleted'),
                      backgroundColor: greenColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: redColor,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyle.eTextStyle.copyWith(color: redColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 10mb)
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File size exceeds 10mb limit'),
                backgroundColor: redColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          uploadedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryWeightController.dispose();
    _courseBloc.close();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toLowerCase()}';
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xff16A765); // Default color if parsing fails
    }
  }

  // Helper to format weight for display (converts decimal to percentage)
  String _formatWeight(String weight) {
    try {
      final percentage = double.parse(weight);
      if (percentage == percentage.roundToDouble()) {
        return '${percentage.toInt()}%';
      } else {
        return '${percentage.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}%';
      }
    } catch (e) {
      return '$weight%';
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final courseId = widget.courseId;

      // Step 2: Upload Attachment (if file is selected)
      if (_selectedFile != null) {
        print('📎 Uploading attachment...');
        final attachmentDataSource = AttachmentRemoteDataSourceImpl(
          dioClient: DioClient(),
        );
        final attachmentRepo = AttachmentRepositoryImpl(
          remoteDataSource: attachmentDataSource,
        );

        await attachmentRepo.createAttachment(
          file: _selectedFile!,
          course: courseId,
        );
        print('✅ Attachment uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: redColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        contentPadding: EdgeInsets.zero,
        content: CustomColorPickerWidget(
          initialColor: selectedColor,
          onColorSelected: (color) {
            setState(() {
              selectedColor = color;
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? existingCategory}) {
    final isEdit = existingCategory != null;

    // Pre-fill form if editing
    if (isEdit) {
      _categoryNameController.text = existingCategory.title;
      // Convert weight double to percentage for display (e.g., 0.20 -> "20")
      try {
        // final weightValue = (existingCategory.weight ?? 0.0) * 100;
        _categoryWeightController.text = (existingCategory.weight ?? 0.0)
            .toStringAsFixed(0);
      } catch (e) {
        _categoryWeightController.text = '';
      }
      selectedColor = _hexToColor(existingCategory.color);
    } else {
      _categoryNameController.clear();
      _categoryWeightController.clear();
      selectedColor = const Color(0xff16a765);
    }

    bool isCreatingCategory = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: transparentColor,
          child: Container(
            padding: EdgeInsets.all(24.h),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(16.adaptSize),
              boxShadow: [
                BoxShadow(
                  color: blackColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      isEdit ? 'Edit Category' : 'Add New Category',
                      style: AppTextStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 28.v),
                  Text(
                    'Title',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  TextField(
                    controller: _categoryNameController,
                    decoration: InputDecoration(
                      hintText: '',
                      hintStyle: AppTextStyle.iTextStyle.copyWith(
                        color: textColor.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: softGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.adaptSize),
                        borderSide: BorderSide(
                          color: greyColor.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.adaptSize),
                        borderSide: BorderSide(
                          color: greyColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.adaptSize),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 10.v,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.v),
                  Text(
                    'Weight (%)',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  TextField(
                    controller: _categoryWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '',
                      hintStyle: AppTextStyle.iTextStyle.copyWith(
                        color: textColor.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: softGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.adaptSize),
                        borderSide: BorderSide(
                          color: greyColor.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.adaptSize),
                        borderSide: BorderSide(
                          color: greyColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.adaptSize),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 10.v,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.v),
                  Row(
                    children: [
                      Text(
                        'Color',
                        style: AppTextStyle.cTextStyle.copyWith(
                          color: blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16.h),
                      GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 33,
                          height: 33,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: greyColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.v),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCreatingCategory
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.v),
                            side: BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCreatingCategory
                              ? null
                              : () {
                                  if (_categoryNameController.text
                                      .trim()
                                      .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please enter a category name',
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(color: whiteColor),
                                        ),
                                        backgroundColor: redColor,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isCreatingCategory = true;
                                  });

                                  String weightValue = "0";
                                  if (_categoryWeightController.text
                                      .trim()
                                      .isNotEmpty) {
                                    weightValue = _categoryWeightController.text
                                        .trim();
                                  }

                                  final request = CategoryRequestModel(
                                    title: _categoryNameController.text.trim(),
                                    weight: weightValue,
                                    color: _colorToHex(selectedColor),
                                  );

                                  // Create or Update based on mode
                                  if (isEdit) {
                                    _courseBloc.add(
                                      UpdateCategoryEvent(
                                        groupId: widget.courseGroupId,
                                        courseId: widget.courseId,
                                        categoryId: existingCategory.id,
                                        request: request,
                                      ),
                                    );
                                  } else {
                                    _courseBloc.add(
                                      CreateCategoryEvent(
                                        groupId: widget.courseGroupId,
                                        courseId: widget.courseId,
                                        request: request,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCreatingCategory
                                ? primaryColor.withOpacity(0.6)
                                : primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.v),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                          ),
                          child: isCreatingCategory
                              ? SizedBox(
                                  width: 20.adaptSize,
                                  height: 20.adaptSize,
                                  child: CircularProgressIndicator(
                                    color: whiteColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Confirm',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _courseBloc,
      child: BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CategoryCreated) {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Category added successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: greenColor,
                duration: const Duration(seconds: 2),
              ),
            );

            _courseBloc.add(
              FetchCategoriesEvent(
                groupId: widget.courseGroupId,
                courseId: widget.courseId,
              ),
            );
          } else if (state is CategoryUpdated) {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Category updated successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: greenColor,
                duration: const Duration(seconds: 2),
              ),
            );

            _courseBloc.add(
              FetchCategoriesEvent(
                groupId: widget.courseGroupId,
                courseId: widget.courseId,
              ),
            );
          } else if (state is CategoryDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Category deleted successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: greenColor,
                duration: const Duration(seconds: 2),
              ),
            );

            _courseBloc.add(
              FetchCategoriesEvent(
                groupId: widget.courseGroupId,
                courseId: widget.courseId,
              ),
            );
          } else if (state is CategoryDeleteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to delete category',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      state.message,
                      style: AppTextStyle.iTextStyle.copyWith(
                        color: whiteColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                backgroundColor: redColor,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CategoryCreateError ||
              state is CategoryUpdateError) {
            if (Navigator.canPop(context)) {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) {
                navigator.pop();
              }
            }

            // Get error message based on state type
            final errorTitle = state is CategoryCreateError
                ? 'Failed to create category'
                : 'Failed to update category';
            final errorMessage = state is CategoryCreateError
                ? state.message
                : (state as CategoryUpdateError).message;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorTitle,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      errorMessage,
                      style: AppTextStyle.iTextStyle.copyWith(
                        color: whiteColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                backgroundColor: redColor,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: softGrey,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.v,
                      horizontal: 12.h,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(color: whiteColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.keyboard_arrow_left,
                            color: blackColor,
                          ),
                        ),
                        Text(
                          widget.isEdit ? 'Edit Class' : 'Add Class',
                          style: AppTextStyle.aTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.import_contacts, color: transparentColor),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.h,
                      vertical: 12.v,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 20.v,
                      ),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(16.adaptSize),
                        boxShadow: [
                          BoxShadow(
                            color: blackColor.withOpacity(0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: EasyStepper(
                        activeStep: 2,
                        lineStyle: LineStyle(
                          lineLength: 60.h,
                          lineThickness: 3,
                          lineSpace: 4,
                          lineType: LineType.normal,
                          defaultLineColor: greyColor.withOpacity(0.3),
                          finishedLineColor: primaryColor,
                          activeLineColor: primaryColor,
                        ),
                        activeStepBorderColor: primaryColor,
                        activeStepIconColor: whiteColor,
                        activeStepBackgroundColor: primaryColor,
                        activeStepTextColor: primaryColor,
                        finishedStepBorderColor: primaryColor,
                        finishedStepBackgroundColor: primaryColor.withOpacity(
                          0.1,
                        ),
                        finishedStepIconColor: primaryColor,
                        finishedStepTextColor: blackColor,
                        unreachedStepBorderColor: greyColor.withOpacity(0.3),
                        unreachedStepBackgroundColor: softGrey,
                        unreachedStepIconColor: greyColor,
                        unreachedStepTextColor: textColor.withOpacity(0.5),
                        borderThickness: 2,
                        internalPadding: 12,
                        showLoadingAnimation: false,
                        stepRadius: 28.adaptSize,
                        showStepBorder: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.h,
                          vertical: 8.v,
                        ),
                        stepShape: StepShape.circle,
                        stepBorderRadius: 15,
                        steppingEnabled: true,
                        disableScroll: true,
                        onStepReached: (index) {
                          if (index == 2) return; // already here

                          if (index == 0) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.addClassesScreen,
                              arguments: {
                                'courseGroupId': widget.courseGroupId,
                                'courseId': widget.courseId,
                                'isEdit': true,
                              },
                            );
                            return;
                          }

                          if (index == 1) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.scheduleAddClass,
                              arguments: {
                                'courseId': widget.courseId,
                                'courseGroupId': widget.courseGroupId,
                                'isEdit': true,
                              },
                            );
                          }
                        },
                        steps: [
                          EasyStep(
                            customStep: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.1),
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.menu_book,
                                  color: primaryColor,
                                  size: 20.adaptSize,
                                ),
                              ),
                            ),
                            customTitle: Padding(
                              padding: EdgeInsets.only(top: 8.v),
                              child: Text(
                                'Details',
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            topTitle: false,
                          ),
                          EasyStep(
                            customStep: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.1),
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.calendar_month,
                                  color: primaryColor,
                                  size: 20.adaptSize,
                                ),
                              ),
                            ),
                            customTitle: Padding(
                              padding: EdgeInsets.only(top: 8.v),
                              child: Text(
                                'Schedule',
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            topTitle: false,
                          ),
                          EasyStep(
                            customStep: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.category_outlined,
                                  color: whiteColor,
                                  size: 20.adaptSize,
                                ),
                              ),
                            ),
                            customTitle: Padding(
                              padding: EdgeInsets.only(top: 8.v),
                              child: Text(
                                'Categories',
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            topTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: AppTextStyle.bTextStyle.copyWith(
                                color: blackColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showCategoryDialog,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.h,
                                  vertical: 8.v,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(
                                    8.adaptSize,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: whiteColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.v),
                        BlocBuilder<CourseBloc, CourseState>(
                          buildWhen: (previous, current) {
                            return current is CategoriesLoading ||
                                current is CategoriesLoaded ||
                                current is CategoriesError;
                          },
                          builder: (context, state) {
                            if (state is CategoriesLoading) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.v),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      whiteColor,
                                    ),
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            } else if (state is CategoriesError) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.v),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: redColor,
                                        size: 40.adaptSize,
                                      ),
                                      SizedBox(height: 8.v),
                                      Text(
                                        state.message,
                                        style: AppTextStyle.cTextStyle.copyWith(
                                          color: redColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (state is CategoriesLoaded) {
                              if (state.categories.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.v),
                                    child: Text(
                                      'No categories added yet',
                                      style: AppTextStyle.cTextStyle.copyWith(
                                        color: textColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: state.categories.map((category) {
                                  final categoryColor = _hexToColor(
                                    category.color,
                                  );

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12.v),
                                    padding: EdgeInsets.all(16.h),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      borderRadius: BorderRadius.circular(
                                        10.adaptSize,
                                      ),
                                      border: Border.all(
                                        color: softGrey,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: blackColor.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: categoryColor,
                                            borderRadius: BorderRadius.circular(
                                              3.adaptSize,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category.title,
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: blackColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              SizedBox(height: 4.v),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Weight: ${_formatWeight(category.weight?.toString() ?? '0')}',
                                                    style: AppTextStyle
                                                        .iTextStyle
                                                        .copyWith(
                                                          color: textColor
                                                              .withOpacity(0.6),
                                                          fontSize: 12.fSize,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        GestureDetector(
                                          onTap: () {
                                            _showCategoryDialog(
                                              existingCategory: category,
                                            );
                                          },
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: primaryColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (confirmContext) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.adaptSize,
                                                        ),
                                                  ),
                                                  title: Text(
                                                    'Delete Category',
                                                    style: AppTextStyle
                                                        .bTextStyle
                                                        .copyWith(
                                                          color: textColor,
                                                        ),
                                                  ),
                                                  content: Text(
                                                    'Are you sure you want to delete "${category.title}"? This action cannot be undone.',
                                                    style: AppTextStyle
                                                        .cTextStyle
                                                        .copyWith(
                                                          color: textColor
                                                              .withOpacity(0.7),
                                                        ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                          confirmContext,
                                                        );
                                                      },
                                                      child: Text(
                                                        'Cancel',
                                                        style: AppTextStyle
                                                            .cTextStyle
                                                            .copyWith(
                                                              color: textColor,
                                                            ),
                                                      ),
                                                    ),

                                                    Icon(Icons.edit),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                          confirmContext,
                                                        );
                                                        _courseBloc.add(
                                                          DeleteCategoryEvent(
                                                            groupId: widget
                                                                .courseGroupId,
                                                            courseId:
                                                                widget.courseId,
                                                            categoryId:
                                                                category.id,
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            redColor,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.adaptSize,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Delete',
                                                        style: AppTextStyle
                                                            .cTextStyle
                                                            .copyWith(
                                                              color: whiteColor,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: redColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }

                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.v),
                                child: Text(
                                  'Loading categories...',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: textColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 32.v),
                        Divider(
                          color: greyColor.withOpacity(0.2),
                          thickness: 1,
                        ),
                        SizedBox(height: 32.v),

                        // Attachments Section
                        Text(
                          'Attachments',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12.v),

                        if (_serverAttachments.isNotEmpty) ...[
                          ..._serverAttachments.map((att) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 10.v),
                              padding: EdgeInsets.all(12.h),
                              decoration: BoxDecoration(
                                color: whiteColor,
                                border: Border.all(color: softGrey, width: 1),
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8.h),
                                  Expanded(
                                    child: Text(
                                      att.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: blackColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.h),
                                  GestureDetector(
                                    onTap: () => _confirmDeleteAttachment(att),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: redColor,
                                      size: 20.adaptSize,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 12.v),
                        ],

                        // File Upload Container
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.h,
                              vertical: 16.v,
                            ),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: uploadedFileName != null
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: blackColor.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: uploadedFileName != null
                                ? Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.insert_drive_file,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12.h),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              uploadedFileName!,
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2.v),
                                            Text(
                                              'Tap to change file',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor
                                                        .withOpacity(0.5),
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: redColor,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            uploadedFileName = null;
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        color: primaryColor,
                                        size: 24,
                                      ),
                                      SizedBox(width: 12.h),
                                      Text(
                                        'Choose File',
                                        style: AppTextStyle.eTextStyle.copyWith(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        SizedBox(height: 32.v),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _isSubmitting ? null : _handleSubmit();

                              // Close and toast once all is triggered
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.isEdit
                                        ? 'Class updated successfully!'
                                        : 'Class created successfully!',
                                    style: AppTextStyle.cTextStyle.copyWith(
                                      color: whiteColor,
                                    ),
                                  ),
                                  backgroundColor: greenColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 14.v),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: whiteColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.v),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
