// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/course_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/course_model.dart';
import 'package:heliumedu/data/models/planner/course_request_model.dart';
import 'package:heliumedu/data/repositories/course_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart';
import 'package:heliumedu/presentation/widgets/custom_class_textfield.dart';
import 'package:heliumedu/presentation/widgets/custom_text_button.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';
import 'package:heliumedu/utils/custom_calendar_textfield.dart';
import 'package:heliumedu/utils/custom_color_picker.dart';
import 'package:easy_stepper/easy_stepper.dart';

class AddClassesScreen extends StatefulWidget {
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;

  const AddClassesScreen({
    super.key,
    required this.courseGroupId,
    this.courseId,
    this.isEdit = false,
  });

  @override
  State<AddClassesScreen> createState() => _AddClassesScreenState();
}

class _AddClassesScreenState extends State<AddClassesScreen> {
  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();

  // Form State
  Color selectedColor = const Color(
    0xFF16a765,
  ); // Valid HeliumEdu color - Green
  bool isOnline = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;
  int? _stepperTargetIndex;
  
  // Course group default dates
  String? _groupStartDate;
  String? _groupEndDate;

  // Bloc instance
  late CourseBloc _courseBloc;

  @override
  void initState() {
    super.initState();
    _courseBloc = CourseBloc(
      courseRepository: CourseRepositoryImpl(
        remoteDataSource: CourseRemoteDataSourceImpl(dioClient: DioClient()),
      ),
    );

    // Fetch course group details to get default dates
    _fetchCourseGroupDetails();

    // Fetch course details if editing
    if (widget.isEdit && widget.courseId != null) {
      _courseBloc.add(
        FetchCourseByIdEvent(
          groupId: widget.courseGroupId,
          courseId: widget.courseId!,
        ),
      );
    }
  }

  // Fetch course group details to get default start/end dates
  Future<void> _fetchCourseGroupDetails() async {
    try {
      final dataSource = CourseRemoteDataSourceImpl(dioClient: DioClient());
      final groups = await dataSource.getCourseGroups();
      final group = groups.firstWhere(
        (g) => g.id == widget.courseGroupId,
        orElse: () => groups.first,
      );
      
      setState(() {
        _groupStartDate = group.startDate;
        _groupEndDate = group.endDate;
        
        // If user hasn't set dates and group has dates, display them
        if (_startDate == null && _groupStartDate != null && _groupStartDate!.isNotEmpty) {
          try {
            _startDate = DateTime.parse(_groupStartDate!);
          } catch (e) {
            print('Error parsing group start date: $e');
          }
        }
        
        if (_endDate == null && _groupEndDate != null && _groupEndDate!.isNotEmpty) {
          try {
            _endDate = DateTime.parse(_groupEndDate!);
          } catch (e) {
            print('Error parsing group end date: $e');
          }
        }
      });
    } catch (e) {
      print('Error fetching course group: $e');
    }
  }

  // Helper to pre-fill form with course data
  void _prefillForm(CourseModel course) {
    _titleController.text = course.title;
    _roomController.text = course.room;
    _websiteController.text = course.website;
    _teacherNameController.text = course.teacherName;
    _teacherEmailController.text = course.teacherEmail;
    _creditsController.text = course.credits;

    setState(() {
      isOnline = course.isOnline;

      // Parse dates
      try {
        _startDate = DateTime.parse(course.startDate);
        _endDate = DateTime.parse(course.endDate);
      } catch (e) {
        print('Error parsing dates: $e');
      }

      // Parse color
      try {
        selectedColor = Color(int.parse('0xFF${course.color.substring(1)}'));
      } catch (e) {
        print('Error parsing color: $e');
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    _websiteController.dispose();
    _teacherNameController.dispose();
    _teacherEmailController.dispose();
    _creditsController.dispose();
    _courseBloc.close();
    super.dispose();
  }

  // Helper to format date to API format (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper to format date for display
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

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toLowerCase()}';
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

  void _validateAndCreateCourse() {
    // Use user dates if set, otherwise fallback to course group dates
    String startDateStr;
    String endDateStr;
    
    if (_startDate != null) {
      startDateStr = _formatDateForApi(_startDate!);
    } else if (_groupStartDate != null && _groupStartDate!.isNotEmpty) {
      startDateStr = _groupStartDate!;
    } else {
      startDateStr = ''; // Will be handled by API or use current date
    }
    
    if (_endDate != null) {
      endDateStr = _formatDateForApi(_endDate!);
    } else if (_groupEndDate != null && _groupEndDate!.isNotEmpty) {
      endDateStr = _groupEndDate!;
    } else {
      endDateStr = ''; // Will be handled by API or use current date
    }
    
    // Create request model
    final request = CourseRequestModel(
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      room: _roomController.text.trim(),
      credits: _creditsController.text.trim().isEmpty
          ? '0'
          : _creditsController.text.trim(),
      color: _colorToHex(selectedColor),
      website: _websiteController.text.trim(),
      isOnline: isOnline,
      teacherName: _teacherNameController.text.trim(),
      teacherEmail: _teacherEmailController.text.trim(),
      startDate: startDateStr,
      endDate: endDateStr,
      courseGroup: widget.courseGroupId,
    );

    // Trigger BLoC event - Create or Update based on mode
    if (widget.isEdit && widget.courseId != null) {
      _courseBloc.add(
        UpdateCourseEvent(
          groupId: widget.courseGroupId,
          courseId: widget.courseId!,
          request: request,
        ),
      );
    } else {
      _courseBloc.add(CreateCourseEvent(request: request));
    }
  }

  void _handleStepperTap(int index) {
    if (index == 0) return;

    // If already have a courseId (edit flow), just navigate
    if (widget.courseId != null) {
      if (index == 1) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.scheduleAddClass,
          arguments: {
            'courseId': widget.courseId,
            'courseGroupId': widget.courseGroupId,
            'isEdit': widget.isEdit,
          },
        );
      } else if (index == 2) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.categoriesAddClass,
          arguments: {
            'courseId': widget.courseId,
            'courseGroupId': widget.courseGroupId,
            'isEdit': widget.isEdit,
          },
        );
      }
      return;
    }

    _stepperTargetIndex = index;

    // Use user dates if set, otherwise fallback to course group dates
    String startDateStr;
    String endDateStr;
    
    if (_startDate != null) {
      startDateStr = _formatDateForApi(_startDate!);
    } else if (_groupStartDate != null && _groupStartDate!.isNotEmpty) {
      startDateStr = _groupStartDate!;
    } else {
      startDateStr = '';
    }
    
    if (_endDate != null) {
      endDateStr = _formatDateForApi(_endDate!);
    } else if (_groupEndDate != null && _groupEndDate!.isNotEmpty) {
      endDateStr = _groupEndDate!;
    } else {
      endDateStr = '';
    }

    final request = CourseRequestModel(
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      room: _roomController.text.trim(),
      credits: _creditsController.text.trim().isEmpty
          ? '0'
          : _creditsController.text.trim(),
      color: _colorToHex(selectedColor),
      website: _websiteController.text.trim(),
      isOnline: isOnline,
      teacherName: _teacherNameController.text.trim(),
      teacherEmail: _teacherEmailController.text.trim(),
      startDate: startDateStr,
      endDate: endDateStr,
      courseGroup: widget.courseGroupId,
    );

    _courseBloc.add(CreateCourseEvent(request: request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _courseBloc,
      child: BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CourseDetailLoaded) {
            _prefillForm(state.course);
          } else if (state is CourseDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load class: ${state.message}',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: redColor,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is CourseCreating || state is CourseUpdating) {
            setState(() {
              _isCreating = true;
            });
          } else if (state is CourseCreated) {
            setState(() {
              _isCreating = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Class created successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate based on stepper intent; default to Schedule
            final target = _stepperTargetIndex ?? 1;
            if (target == 2) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.categoriesAddClass,
                arguments: {
                  'courseId': state.course.id,
                  'courseGroupId': state.course.courseGroup,
                  'isEdit': false,
                },
              );
            } else {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.scheduleAddClass,
                arguments: {
                  'courseId': state.course.id,
                  'courseGroupId': state.course.courseGroup,
                  'isEdit': false,
                },
              );
            }
          } else if (state is CourseUpdated) {
            setState(() {
              _isCreating = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Class updated successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate to schedule screen with course data
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.scheduleAddClass,
              arguments: {
                'courseId': state.course.id,
                'courseGroupId': state.course.courseGroup,
                'isEdit': true, // Stay in edit mode
              },
            );
          } else if (state is CourseCreateError || state is CourseUpdateError) {
            setState(() {
              _isCreating = false;
            });

            // Get error message based on state type
            final errorTitle = state is CourseCreateError
                ? 'Failed to create class'
                : 'Failed to update class';
            final errorMessage = state is CourseCreateError
                ? state.message
                : (state as CourseUpdateError).message;

            // Show error message with details
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.v,
                    horizontal: 16.h,
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
                      Icon(Icons.import_contacts, color: Colors.transparent),
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
                      activeStep: 0,
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
                        _handleStepperTap(index);
                      },
                      steps: [
                        EasyStep(
                          customStep: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                              border: Border.all(color: primaryColor, width: 2),
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
                                Icons.menu_book,
                                color: whiteColor,
                                size: 20.adaptSize,
                              ),
                            ),
                          ),
                          customTitle: Padding(
                            padding: EdgeInsets.only(top: 8.v),
                            child: Text(
                              'Details',
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
                        EasyStep(
                          customStep: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withOpacity(0.1),
                              border: Border.all(color: primaryColor, width: 2),
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
                              color: primaryColor.withOpacity(0.1),
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.category_outlined,
                                color: primaryColor,
                                size: 20.adaptSize,
                              ),
                            ),
                          ),
                          customTitle: Padding(
                            padding: EdgeInsets.only(top: 8.v),
                            child: Text(
                              'Categories',
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
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.v),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Title',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomClassTextField(
                            text: 'Enter Class Title',
                            controller: _titleController,
                          ),
                          SizedBox(height: 14.v),
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
                              setState(() {
                                _startDate = selectedDate;
                              });
                            },
                          ),
                          SizedBox(height: 14.v),
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
                              setState(() {
                                _endDate = selectedDate;
                              });
                            },
                          ),
                          SizedBox(height: 14.v),

                          if (!isOnline) ...[
                            Text(
                              'Room',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: blackColor.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 9.v),
                            CustomClassTextField(
                              text: 'Enter Room No.',
                              controller: _roomController,
                            ),
                            SizedBox(height: 14.v),
                          ],

                          Text(
                            'Website',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomClassTextField(
                            text: 'Enter Website',
                            controller: _websiteController,
                          ),
                          SizedBox(height: 14.v),
                          Text(
                            'Teacher Name',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomClassTextField(
                            text: 'Enter Teacher Name',
                            controller: _teacherNameController,
                          ),
                          SizedBox(height: 14.v),
                          Text(
                            'Teacher Email',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomClassTextField(
                            text: 'Enter Teacher Email',
                            controller: _teacherEmailController,
                          ),
                          SizedBox(height: 14.v),
                          Text(
                            'Credits hour',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 9.v),
                          CustomClassTextField(
                            text: 'Enter Class Credit Hours',
                            controller: _creditsController,
                          ),
                          SizedBox(height: 14.v),

                          Row(
                            children: [
                              Checkbox(
                                value: isOnline,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isOnline = newValue ?? false;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text(
                                'Online',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                              SizedBox(width: 44.h),
                              Text(
                                'Color',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: blackColor.withOpacity(0.8),
                                ),
                              ),
                              SizedBox(width: 12.h),
                              GestureDetector(
                                onTap: _showColorPicker,
                                child: Container(
                                  width: 33,
                                  height: 33,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 33.v),
                          SizedBox(
                            width: double.infinity,
                            child: _isCreating
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(
                                        whiteColor,
                                      ),
                                      color: primaryColor,
                                    ),
                                  )
                                : CustomTextButton(
                                    buttonText: 'Save',
                                    onPressed: _validateAndCreateCourse,
                                  ),
                          ),
                          SizedBox(height: 22.v),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
