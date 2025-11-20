// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/course_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/course_model.dart';
import 'package:heliumedu/data/models/planner/course_group_request_model.dart';
import 'package:heliumedu/data/models/planner/course_group_response_model.dart';
import 'package:heliumedu/data/repositories/course_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart';
import 'package:heliumedu/presentation/widgets/custom_class_textfield.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';
import 'package:heliumedu/utils/custom_calendar_textfield.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

bool isHide = false;

class _ClassesScreenState extends State<ClassesScreen> {
  // Form controllers and variables
  final TextEditingController _titleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreatingGroup = false;

  // Course groups
  List<CourseGroupResponseModel> _courseGroups = [];
  String? _selectedCourseGroup;
  int? _selectedCourseGroupId;
  bool _isLoadingGroups = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return primaryColor;
    }
  }

  void _showCourseGroupDialog(
    BuildContext context, {
    CourseGroupResponseModel? existingGroup,
  }) {
    final isEdit = existingGroup != null;

    if (isEdit) {
      _titleController.text = existingGroup.title;
      try {
        _startDate = DateTime.parse(existingGroup.startDate);
        _endDate = DateTime.parse(existingGroup.endDate);
        setState(() {
          isHide = !existingGroup.shownOnCalendar;
        });
      } catch (e) {
        _startDate = null;
        _endDate = null;
      }
    } else {
      _titleController.clear();
      _startDate = null;
      _endDate = null;
      setState(() {
        isHide = false;
      });
    }

    final courseBloc = context.read<CourseBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String? errorMessage;

        return BlocProvider.value(
          value: courseBloc,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return BlocListener<CourseBloc, CourseState>(
                listener: (context, state) {
                  if (state is CourseGroupCreateError ||
                      state is CourseGroupUpdateError) {
                    setDialogState(() {
                      errorMessage = state is CourseGroupCreateError
                          ? state.message
                          : (state as CourseGroupUpdateError).message;
                      _isCreatingGroup = false;
                    });
                  } else if (state is CourseGroupCreated ||
                      state is CourseGroupUpdated) {
                    Navigator.pop(dialogContext);
                  } else if (state is CourseGroupCreating ||
                      state is CourseGroupUpdating) {
                    setDialogState(() {
                      _isCreatingGroup = true;
                      errorMessage = null; // Clear error when loading starts
                    });
                  }
                },
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  child: SingleChildScrollView(
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
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
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
                            text: 'Enter Fall Semester 2025',
                            controller: _titleController,
                          ),
                          SizedBox(height: 12.v),
                          Text(
                            'From',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomCalendarTextfield(
                            text: _startDate != null
                                ? _formatDateForDisplay(_startDate!)
                                : 'Select Date',
                            onDateSelected: (selectedDate) {
                              setDialogState(() {
                                _startDate = selectedDate;
                                errorMessage =
                                    null; // Clear error when user interacts
                              });
                            },
                          ),
                          SizedBox(height: 12.v),
                          Text(
                            'To',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomCalendarTextfield(
                            text: _endDate != null
                                ? _formatDateForDisplay(_endDate!)
                                : 'Select Date',
                            onDateSelected: (selectedDate) {
                              setDialogState(() {
                                _endDate = selectedDate;
                                errorMessage =
                                    null; // Clear error when user interacts
                              });
                            },
                          ),
                          SizedBox(height: 12.v),
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
                                  "Hide this group's classes and assignments from the Calendar",
                                  style: AppTextStyle.iTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.v),
                          BlocBuilder<CourseBloc, CourseState>(
                            buildWhen: (previous, current) {
                              return current is CourseGroupCreating ||
                                  current is CourseGroupUpdating ||
                                  current is CourseGroupCreated ||
                                  current is CourseGroupUpdated ||
                                  current is CourseGroupCreateError ||
                                  current is CourseGroupUpdateError;
                            },
                            builder: (context, state) {
                              final isLoading = _isCreatingGroup;

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
                                        color: isLoading
                                            ? textColor.withOpacity(0.5)
                                            : textColor,
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
                                                    'Please enter a title';
                                              });
                                              return;
                                            }

                                            if (_startDate == null) {
                                              setDialogState(() {
                                                errorMessage =
                                                    'Please select a start date';
                                              });
                                              return;
                                            }

                                            if (_endDate == null) {
                                              setDialogState(() {
                                                errorMessage =
                                                    'Please select an end date';
                                              });
                                              return;
                                            }

                                            if (_endDate!.isBefore(
                                              _startDate!,
                                            )) {
                                              setDialogState(() {
                                                errorMessage =
                                                    'End date must be after start date';
                                              });
                                              return;
                                            }

                                            final request =
                                                CourseGroupRequestModel(
                                                  title: _titleController.text
                                                      .trim(),
                                                  startDate: _formatDateForApi(
                                                    _startDate!,
                                                  ),
                                                  endDate: _formatDateForApi(
                                                    _endDate!,
                                                  ),
                                                  shownOnCalendar: !isHide,
                                                );
                                            if (isEdit) {
                                              context.read<CourseBloc>().add(
                                                UpdateCourseGroupEvent(
                                                  groupId: existingGroup.id,
                                                  request: request,
                                                ),
                                              );
                                            } else {
                                              context.read<CourseBloc>().add(
                                                CreateCourseGroupEvent(
                                                  request: request,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLoading
                                          ? primaryColor.withOpacity(0.6)
                                          : primaryColor,
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
                                            child: CircularProgressIndicator(
                                              color: whiteColor,
                                              strokeWidth: 2,
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final courseColor = _hexToColor(course.color);

    return Container(
      margin: EdgeInsets.only(bottom: 16.v),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(color: blackColor.withOpacity(0.08), width: 1),
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
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.h,
                    vertical: 6.v,
                  ),
                  decoration: BoxDecoration(
                    color: courseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.adaptSize),
                    border: Border.all(
                      color: courseColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.adaptSize,
                        height: 6.adaptSize,
                        decoration: BoxDecoration(
                          color: courseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.h),
                      Expanded(
                        child: Text(
                          course.title.isNotEmpty
                              ? course.title
                              : 'Untitled Class',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: courseColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 8.h),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addClassesScreen,
                    arguments: {
                      'courseGroupId': course.courseGroup,
                      'courseId': course.id,
                      'isEdit': true,
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(6.adaptSize),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.adaptSize),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18.adaptSize,
                    color: primaryColor,
                  ),
                ),
              ),

              SizedBox(width: 8.h),

              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext confirmContext) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                        ),
                        title: Text(
                          'Delete Class',
                          style: AppTextStyle.bTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete "${course.title}"? This action cannot be undone.',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(confirmContext);
                            },
                            child: Text(
                              'Cancel',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(confirmContext);
                              context.read<CourseBloc>().add(
                                DeleteCourseEvent(
                                  groupId: course.courseGroup,
                                  courseId: course.id,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: redColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: whiteColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(6.adaptSize),
                  decoration: BoxDecoration(
                    color: redColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.adaptSize),
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

          SizedBox(height: 16.v),

          if (course.teacherName.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.teacherName,
                  style: AppTextStyle.aTextStyle.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.v),
              ],
            ),

          // Room Info
          if (course.room.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.room_outlined,
                  size: 16.adaptSize,
                  color: textColor.withOpacity(0.4),
                ),
                SizedBox(width: 4.h),
                Text(
                  course.room,
                  style: AppTextStyle.cTextStyle.copyWith(
                    color: textColor.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),

          SizedBox(height: 12.v),

          // Divider
          Container(height: 1, color: blackColor.withOpacity(0.08)),

          SizedBox(height: 12.v),

          // Date Range
          Row(
            children: [
              Icon(
                Icons.date_range_outlined,
                size: 16.adaptSize,
                color: textColor.withOpacity(0.4),
              ),
              SizedBox(width: 4.h),
              Text(
                course.getFormattedDateRange(),
                style: AppTextStyle.cTextStyle.copyWith(
                  color: textColor.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // Schedules Section
          if (course.schedules.isNotEmpty) ...[
            SizedBox(height: 16.v),

            // Schedules Header
            Text(
              'Class Schedule',
              style: AppTextStyle.cTextStyle.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            SizedBox(height: 8.v),

            // Schedules Container
            ...course.schedules.map((schedule) {
              final activeDays = schedule.getActiveDays();

              return Container(
                margin: EdgeInsets.only(bottom: 8.v),
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: courseColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.adaptSize),
                  border: Border.all(
                    color: courseColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Days of week
                    if (activeDays.isNotEmpty)
                      Wrap(
                        spacing: 6.h,
                        runSpacing: 6.v,
                        children: activeDays.map((day) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.h,
                              vertical: 4.v,
                            ),
                            decoration: BoxDecoration(
                              color: courseColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.adaptSize),
                            ),
                            child: Text(
                              day,
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: courseColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    if (activeDays.isNotEmpty) SizedBox(height: 8.v),

                    // Time display for first active day
                    if (activeDays.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14.adaptSize,
                            color: textColor.withOpacity(0.4),
                          ),
                          SizedBox(width: 4.h),
                          Text(
                            schedule.getTimeForDay(activeDays.first),
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = CourseBloc(
          courseRepository: CourseRepositoryImpl(
            remoteDataSource: CourseRemoteDataSourceImpl(
              dioClient: DioClient(),
            ),
          ),
        );
        // Load groups first so we can preselect the most recently created group
        bloc.add(FetchCourseGroupsEvent());
        return bloc;
      },
      child: Builder(
        builder: (context) {
          return BlocListener<CourseBloc, CourseState>(
            listener: (context, state) {
              // Course delete listeners
              if (state is CourseDeleting) {
                // Optionally show loading indicator
              } else if (state is CourseDeleted) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class deleted successfully!',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Refresh courses for the selected group
                if (_selectedCourseGroupId != null) {
                  context.read<CourseBloc>().add(
                    FetchCoursesByGroupEvent(groupId: _selectedCourseGroupId!),
                  );
                }
              } else if (state is CourseDeleteError) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Failed to delete class',
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
              }

              // Course group listeners
              if (state is CourseGroupsLoading) {
                setState(() {
                  _isLoadingGroups = true;
                });
              } else if (state is CourseGroupsLoaded) {
                setState(() {
                  _isLoadingGroups = false;
                  _courseGroups = state.courseGroups;
                  // Select the most recently created group (assumed highest id)
                  if (_courseGroups.isNotEmpty &&
                      _selectedCourseGroup == null) {
                    _courseGroups.sort((a, b) => b.id.compareTo(a.id));
                    _selectedCourseGroup = _courseGroups.first.title;
                    _selectedCourseGroupId = _courseGroups.first.id;
                  }
                });

                // Fetch courses for the first group
                if (_selectedCourseGroupId != null) {
                  context.read<CourseBloc>().add(
                    FetchCoursesByGroupEvent(groupId: _selectedCourseGroupId!),
                  );
                }
              } else if (state is CourseGroupsError) {
                setState(() {
                  _isLoadingGroups = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: redColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (state is CourseGroupCreated) {
                setState(() {
                  _isCreatingGroup = false;
                  // Add newly created group to dropdown immediately
                  _courseGroups.add(state.courseGroup);
                  // Set it as selected
                  _selectedCourseGroup = state.courseGroup.title;
                  _selectedCourseGroupId = state.courseGroup.id;
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class group created successfully!',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Fetch courses for the newly created group
                context.read<CourseBloc>().add(
                  FetchCoursesByGroupEvent(groupId: state.courseGroup.id),
                );
              } else if (state is CourseGroupCreateError) {
                setState(() {
                  _isCreatingGroup = false;
                });

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: redColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is CourseGroupCreating) {
                setState(() {
                  _isCreatingGroup = true;
                });
              } else if (state is CourseGroupDeleted) {
                setState(() {
                  // Remove deleted group from dropdown
                  _courseGroups.removeWhere(
                    (g) => g.id == state.deletedGroupId,
                  );
                  // Reset selection if deleted group was selected
                  if (_courseGroups.isEmpty) {
                    _selectedCourseGroup = null;
                    _selectedCourseGroupId = null;
                  } else if (_selectedCourseGroup != null) {
                    // Check if selected group still exists
                    final exists = _courseGroups.any(
                      (g) => g.title == _selectedCourseGroup,
                    );
                    if (!exists) {
                      _selectedCourseGroup = _courseGroups.first.title;
                      _selectedCourseGroupId = _courseGroups.first.id;
                    }
                  }
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class group deleted successfully!',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Fetch courses for the new selected group (or clear if none left)
                if (_selectedCourseGroupId != null) {
                  context.read<CourseBloc>().add(
                    FetchCoursesByGroupEvent(groupId: _selectedCourseGroupId!),
                  );
                } else {
                  // No groups left, emit empty state
                  context.read<CourseBloc>().add(FetchCoursesEvent());
                }
              } else if (state is CourseGroupDeleteError) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: redColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is CourseGroupUpdated) {
                setState(() {
                  _isCreatingGroup = false;
                  // Update the group in dropdown
                  final index = _courseGroups.indexWhere(
                    (g) => g.id == state.courseGroup.id,
                  );
                  if (index != -1) {
                    _courseGroups[index] = state.courseGroup;
                    // Update selection if this was the selected group
                    _selectedCourseGroup = state.courseGroup.title;
                    _selectedCourseGroupId = state.courseGroup.id;
                  }
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class group updated successfully!',
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Refresh courses for the updated group
                context.read<CourseBloc>().add(
                  FetchCoursesByGroupEvent(groupId: state.courseGroup.id),
                );
              } else if (state is CourseGroupUpdateError) {
                setState(() {
                  _isCreatingGroup = false;
                });

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: redColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is CourseGroupUpdating) {
                setState(() {
                  _isCreatingGroup = true;
                });
              }
            },
            child: Scaffold(
              backgroundColor: softGrey,
              body: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 16.v,
                      ),
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
                              Navigator.pushNamed(
                                context,
                                AppRoutes.settingScreen,
                              );
                            },
                            child: Icon(
                              Icons.settings_outlined,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          Text(
                            'Classes',
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: textColor
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.notificationScreen,
                              );
                            },
                            child: Icon(
                              Icons.notifications,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.v),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _courseGroups.isEmpty
                            ? GestureDetector(
                                onTap: _isLoadingGroups
                                    ? null
                                    : () {
                                        // Fetch course groups when clicked
                                        context.read<CourseBloc>().add(
                                          FetchCourseGroupsEvent(),
                                        );
                                      },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.v),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _isLoadingGroups
                                          ? Row(
                                              children: [
                                                SizedBox(
                                                  width: 16.adaptSize,
                                                  height: 16.adaptSize,
                                                  child: CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          whiteColor,
                                                        ),
                                                    color: primaryColor,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                SizedBox(width: 8.h),
                                                Text(
                                                  "Loading groups...",
                                                  style: AppTextStyle.eTextStyle
                                                      .copyWith(
                                                    color: blackColor
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              "Select Group",
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor
                                                        .withOpacity(0.5),
                                                  ),
                                            ),
                                      if (!_isLoadingGroups)
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: blackColor.withOpacity(0.5),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : DropdownButton<String>(
                                icon: Icon(Icons.keyboard_arrow_down),
                                dropdownColor: whiteColor,
                                isExpanded: true,
                                underline: SizedBox(),
                                hint: Text(
                                  "Group Name",
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.5),
                                  ),
                                ),
                                value: _selectedCourseGroup,
                                items:
                                    _courseGroups.map((group) {
                                      return DropdownMenuItem(
                                        value: group.title,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                group.title,
                                                style: AppTextStyle.eTextStyle
                                                    .copyWith(
                                                      color: blackColor
                                                          .withOpacity(0.8),
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 8.h),
                                            GestureDetector(
                                              onTap: () {
                                                // Show edit dialog with existing group data
                                                _showCourseGroupDialog(
                                                  context,
                                                  existingGroup: group,
                                                );
                                              },
                                              child: Icon(
                                                Icons.edit,
                                                size: 20.adaptSize,
                                                color: primaryColor
                                              ),
                                            ),
                                            SizedBox(width: 8.h),
                                            GestureDetector(
                                              onTap: () {
                                                // Show confirmation dialog
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext confirmContext) {
                                                    return AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.adaptSize,
                                                            ),
                                                      ),
                                                      title: Text(
                                                        'Delete Class Group',
                                                        style: AppTextStyle
                                                            .bTextStyle
                                                            .copyWith(
                                                              color: textColor,
                                                            ),
                                                      ),
                                                      content: Text(
                                                        'Are you sure you want to delete "${group.title}"? This action cannot be undone.',
                                                        style: AppTextStyle
                                                            .cTextStyle
                                                            .copyWith(
                                                              color: textColor
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
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
                                                                  color:
                                                                      textColor,
                                                                ),
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              confirmContext,
                                                            );
                                                            // Trigger delete event
                                                            context
                                                                .read<
                                                                  CourseBloc
                                                                >()
                                                                .add(
                                                                  DeleteCourseGroupEvent(
                                                                    groupId:
                                                                        group
                                                                            .id,
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
                                                                  color:
                                                                      whiteColor,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Icon(
                                                Icons.delete,
                                                size: 20.adaptSize,
                                                color: redColor
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList()..add(
                                      DropdownMenuItem<String>(
                                        value: null, // This won't be selectable
                                        enabled: false, // Disable selection
                                        child: GestureDetector(
                                          onTap: () {
                                            // Show add group dialog
                                            _showCourseGroupDialog(context);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.h,
                                              vertical: 8.v,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    6.adaptSize,
                                                  ),
                                              border: Border.all(
                                                color: primaryColor.withOpacity(
                                                  0.3,
                                                ),
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
                                                        fontWeight:
                                                            FontWeight.w500,
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

                                  setState(() {
                                    _selectedCourseGroup = value;
                                    final selectedGroup = _courseGroups
                                        .firstWhere((g) => g.title == value);
                                    _selectedCourseGroupId = selectedGroup.id;
                                  });

                                  // Fetch courses for this group
                                  if (_selectedCourseGroupId != null) {
                                    context.read<CourseBloc>().add(
                                      FetchCoursesByGroupEvent(
                                        groupId: _selectedCourseGroupId!,
                                      ),
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: BlocBuilder<CourseBloc, CourseState>(
                        buildWhen: (previous, current) {
                          return current is CourseInitial ||
                              current is CourseLoading ||
                              current is CourseLoaded ||
                              current is CourseError;
                        },
                        builder: (context, state) {
                          if (state is CourseLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                valueColor: AlwaysStoppedAnimation(whiteColor),
                              ),
                            );
                          } else if (state is CourseError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 60.adaptSize,
                                    color: redColor,
                                  ),
                                  SizedBox(height: 16.v),
                                  Text(
                                    state.message,
                                    style: AppTextStyle.cTextStyle.copyWith(
                                      color: redColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16.v),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<CourseBloc>().add(
                                        FetchCoursesEvent(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.adaptSize,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: AppTextStyle.cTextStyle.copyWith(
                                        color: whiteColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (state is CourseLoaded) {
                            if (state.courses.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 60.adaptSize,
                                      color: textColor.withOpacity(0.3),
                                    ),
                                    SizedBox(height: 16.v),
                                    Text(
                                      'No classes found',
                                      style: AppTextStyle.bTextStyle.copyWith(
                                        color: textColor.withOpacity(0.6),
                                      ),
                                    ),
                                    SizedBox(height: 8.v),
                                    Text(
                                      'Add your first class to get started',
                                      style: AppTextStyle.cTextStyle.copyWith(
                                        color: textColor.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return RefreshIndicator(
                              color: primaryColor,
                              onRefresh: () async {
                                context.read<CourseBloc>().add(
                                  FetchCoursesEvent(),
                                );
                              },
                              child: ListView.builder(
                                padding: EdgeInsets.all(16.h),
                                itemCount: state.courses.length,
                                itemBuilder: (context, index) {
                                  final course = state.courses[index];
                                  return _buildCourseCard(context, course);
                                },
                              ),
                            );
                          }

                          return Center(
                            child: Text(
                              'Loading classes ...',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
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
                  // _showCourseGroupDialog(context);
                  onPressed: () {
                    if (_selectedCourseGroupId != null) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addClassesScreen,
                        arguments: _selectedCourseGroupId,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a class group first',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: whiteColor,
                            ),
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
            ),
          );
        },
      ),
    );
  }
}
