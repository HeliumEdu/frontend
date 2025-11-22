// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/config/app_routes.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/data/datasources/course_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/homework_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/material_remote_data_source.dart';
import 'package:helium_mobile/data/models/planner/category_model.dart';
import 'package:helium_mobile/data/models/planner/course_model.dart';
import 'package:helium_mobile/data/models/planner/homework_request_model.dart';
import 'package:helium_mobile/data/models/planner/homework_response_model.dart';
import 'package:helium_mobile/data/models/planner/material_group_response_model.dart';
import 'package:helium_mobile/data/models/planner/material_model.dart';
import 'package:helium_mobile/data/repositories/course_repository_impl.dart';
import 'package:helium_mobile/data/repositories/homework_repository_impl.dart';
import 'package:helium_mobile/data/repositories/material_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_event.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_state.dart'
    as course_state;
import 'package:helium_mobile/presentation/bloc/homeworkBloc/homework_bloc.dart';
import 'package:helium_mobile/presentation/bloc/homeworkBloc/homework_event.dart';
import 'package:helium_mobile/presentation/bloc/homeworkBloc/homework_state.dart'
    as homework_state;
import 'package:helium_mobile/presentation/bloc/materialBloc/material_bloc.dart';
import 'package:helium_mobile/presentation/bloc/materialBloc/material_event.dart';
import 'package:helium_mobile/presentation/bloc/materialBloc/material_state.dart'
    as material_state;
import 'package:helium_mobile/presentation/widgets/custom_class_textfield.dart';
import 'package:helium_mobile/presentation/widgets/custom_text_button.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_text_style.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:helium_mobile/data/datasources/auth_remote_data_source.dart';
import 'package:helium_mobile/data/repositories/auth_repository_impl.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen>
    with SingleTickerProviderStateMixin {
  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  late TabController _tabController;

  // Edit mode data
  bool isEditMode = false;
  HomeworkResponseModel? existingHomework;
  int? homeworkId;
  int? groupId;
  int? courseId;
  int? selectedCourseId;
  int? selectedCategoryId;
  String _timeZone = 'America/Chicago';
  List<int> selectedMaterialIds = [];
  bool isAllDay = false;
  bool isCompleted = false;
  bool isShowEndDateTime = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double _priorityValue = 50.0;
  List<CourseModel> _courses = [];
  List<CategoryModel> _categories = [];
  List<MaterialModel> _materials = [];
  List<MaterialGroupResponseModel> _materialGroups = [];

  int? _selectedCourseGroupId;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadTimeZone();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        Navigator.pushReplacementNamed(context, AppRoutes.addEventScreen);
      }
    });
  }

  Future<void> _loadTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    String? timeZone = prefs.getString('user_time_zone');

    if (timeZone == null || timeZone.isEmpty) {
      try {
        final dioClient = DioClient();
        final authRepository = AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
        );
        final profile = await authRepository.getProfile();
        final timeZone = profile.settings?.timeZone;
        if (timeZone != null && timeZone.trim().isNotEmpty) {
          await prefs.setString('user_time_zone', timeZone);
        }
      } catch (e) {
        print('⚠️ Failed to load time zone from profile: $e');
      }

      if (timeZone == null || timeZone.isEmpty) return;

      if (mounted && timeZone != _timeZone) {
        setState(() {
          _timeZone = timeZone;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;
    _isInitialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isEditMode'] == true) {
      isEditMode = true;
      existingHomework = args['homework'] as HomeworkResponseModel?;

      if (existingHomework != null) {
        homeworkId = existingHomework!.id;
        if (_courses.isNotEmpty) {
          final course = _courses.firstWhere(
            (c) => c.id == existingHomework!.course,
            orElse: () => _courses.first,
          );
          groupId = course.courseGroup;
          courseId = existingHomework!.course;
          print('🔄 Fetching homework details for ID: $homeworkId');
          if (groupId != null && courseId != null && homeworkId != null) {
            BlocProvider.of<HomeworkBloc>(context).add(
              FetchHomeworkByIdEvent(
                groupId: groupId!,
                courseId: courseId!,
                homeworkId: homeworkId!,
              ),
            );
          }
        } else {
          // If courses aren't loaded yet, populate with existing data
          _populateFieldsFromHomework(existingHomework!);
        }
      }
    }
  }

  void _populateFieldsFromHomework(HomeworkResponseModel homework) {
    print('📝 Populating form with homework data:');
    print('   - Course ID: ${homework.course}');
    print('   - Category ID: ${homework.category}');
    print('   - Materials: ${homework.materials}');

    setState(() {
      homeworkId = homework.id;
      selectedCourseId = homework.course != 0 ? homework.course : null;
      _titleController.text = homework.title;
      isAllDay = homework.allDay;
      isShowEndDateTime = homework.showEndTime;
      isCompleted = homework.completed;

      if (homework.url != null && homework.url!.isNotEmpty) {
        _urlController.text = homework.url!;
      }
      if (homework.comments != null && homework.comments!.isNotEmpty) {
        _detailsController.text = homework.comments!;
      }
      if (homework.currentGrade != null && homework.currentGrade!.isNotEmpty) {
        _gradeController.text = homework.currentGrade!;
      }

      // Set category ID only if it's not 0 or null
      if (homework.category != null && homework.category! > 0) {
        selectedCategoryId = homework.category;
        print('   ✅ Category ID set: $selectedCategoryId');
      } else {
        selectedCategoryId = null;
        print('   ⚠️ No category set (category was ${homework.category})');
      }

      // Set material IDs from the materials list
      if (homework.materials != null && homework.materials!.isNotEmpty) {
        final validMaterials = homework.materials!
            .where((id) => id > 0)
            .toList();
        selectedMaterialIds = validMaterials;
        print('    Material IDs set: $selectedMaterialIds');
      } else {
        selectedMaterialIds = [];
        print('    No materials in homework data');
      }

      _priorityValue = homework.priority.toDouble();

      // Find the course to get groupId
      if (_courses.isNotEmpty && selectedCourseId != null) {
        final course = _courses.firstWhere(
          (c) => c.id == selectedCourseId,
          orElse: () => _courses.first,
        );
        groupId = course.courseGroup;
        courseId = selectedCourseId;

        print('    Fetching categories for course: $courseId, group: $groupId');
        // Fetch categories for the course
        if (groupId != null && courseId != null) {
          BlocProvider.of<CourseBloc>(
            context,
          ).add(FetchCategoriesEvent(groupId: groupId!, courseId: courseId!));

          // Fetch materials for the course
          _fetchMaterialsForCourse(context, courseId!);
        }
      }

      // Parse start date/time
      final timeZone = tz.getLocation(_timeZone);
      try {
        final startDateTime = tz.TZDateTime.from(DateTime.parse(homework.start), timeZone);
        _startDate = startDateTime;
        if (!isAllDay) {
          _startTime = TimeOfDay.fromDateTime(startDateTime);
        }
      } catch (e) {
        print(' Error parsing start date: $e');
      }

      if (homework.end != null) {
        try {
          final endDateTime = tz.TZDateTime.from(DateTime.parse(homework.end!), timeZone);
          _endDate = endDateTime;
          if (!isAllDay) {
            _endTime = TimeOfDay.fromDateTime(endDateTime);
          }
        } catch (e) {
          print(' Error parsing end date: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _urlController.dispose();
    _detailsController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    return time.format(context);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: whiteColor,
              onSurface: blackColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _fetchMaterialsForCourse(BuildContext context, int courseId) async {
    for (var group in _materialGroups) {
      BlocProvider.of<MaterialBloc>(
        context,
      ).add(FetchMaterialsEvent(groupId: group.id));
    }
  }

  String _materialTitleById(int id) {
    final matches = _materials.where((m) => m.id == id);
    if (matches.isNotEmpty) {
      return matches.first.title;
    }
    return 'Unknown';
  }

  Future<void> _openMaterialPicker() async {
    if (selectedCourseId == null || _materials.isEmpty) return;

    final Set<int> tempSelected = selectedMaterialIds.toSet();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            'Select Materials',
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
                  itemCount: _materials.length,
                  itemBuilder: (context, index) {
                    final mat = _materials[index];
                    final checked = tempSelected.contains(mat.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (val) {
                        localSetState(() {
                          if (val == true) {
                            tempSelected.add(mat.id);
                          } else {
                            tempSelected.remove(mat.id);
                          }
                        });
                      },
                      activeColor: primaryColor,
                      title: Text(
                        mat.title,
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
                style: AppTextStyle.eTextStyle.copyWith(color: greyColor),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedMaterialIds = tempSelected.toList();
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

  int _getPriorityValue() {
    return _priorityValue.round();
  }

  String _formatDateTimeToISO(DateTime date, TimeOfDay? time) {
    if (time != null) {
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      final timeZone = tz.getLocation(_timeZone);
      return tz.TZDateTime.from(dateTime, timeZone).toIso8601String();
    }
    return date.toIso8601String();
  }

  void _goToReminderScreen(BuildContext context) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter assignment title'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a class'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (!isAllDay && _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start time'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    final selectedCourse = _courses.firstWhere((c) => c.id == selectedCourseId);

    // Ensure groupId and courseId are set for edit mode
    if (isEditMode && (groupId == null || courseId == null)) {
      groupId = selectedCourse.courseGroup;
      courseId = selectedCourseId;
      print('🔧 Setting missing IDs - GroupId: $groupId, CourseId: $courseId');
    }

    final startDateTime = _formatDateTimeToISO(
      _startDate!,
      isAllDay ? null : _startTime,
    );

    // Ensure backend always receives an end value to avoid validation errors.
    // If End is hidden or not set, default end to start.
    // TODO: the website has logic here that picks a time 30 mins in the future (unless close to midnight, then subtract)
    String endDateTime;
    if (isShowEndDateTime && _endDate != null) {
      endDateTime = _formatDateTimeToISO(_endDate!, isAllDay ? null : _endTime);
    } else {
      endDateTime = startDateTime;
    }

    print('📤 Creating homework request with:');
    print('   - Course: $selectedCourseId');
    print('   - Category: $selectedCategoryId');
    print('   - Materials: $selectedMaterialIds');

    // Determine grade value: -1/100 when not completed, user input when completed
    String gradeValue;
    if (!isCompleted) {
      gradeValue = '-1/100';
    } else {
      final gradeText = _gradeController.text.trim();
      gradeValue = gradeText.isEmpty ? '-1/100' : gradeText;
    }

    final request = HomeworkRequestModel(
      title: _titleController.text.trim(),
      allDay: isAllDay,
      showEndTime: isShowEndDateTime,
      start: startDateTime,
      end: endDateTime,
      priority: _getPriorityValue(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      comments: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      currentGrade: gradeValue,
      completed: isCompleted,
      category: selectedCategoryId,
      materials: selectedMaterialIds.isNotEmpty ? selectedMaterialIds : null,
      course: selectedCourseId!,
    );

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 16),
                Text(
                  isEditMode
                      ? 'Updating assignment...'
                      : 'Creating assignment...',
                  style: AppTextStyle.eTextStyle.copyWith(color: blackColor),
                ),
              ],
            ),
          ),
        ),
      );

      // Call homework API
      final homeworkDataSource = HomeworkRemoteDataSourceImpl(
        dioClient: DioClient(),
      );
      final homeworkRepo = HomeworkRepositoryImpl(
        remoteDataSource: homeworkDataSource,
      );

      int homeworkId;
      if (isEditMode && this.homeworkId != null) {
        // Ensure we have the required IDs for updating
        if (groupId == null || courseId == null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: Missing class information. Please try again.',
              ),
              backgroundColor: redColor,
            ),
          );
          return;
        }

        print('🔄 Updating homework ID: ${this.homeworkId}...');
        final homework = await homeworkRepo.updateHomework(
          groupId: groupId!,
          courseId: courseId!,
          homeworkId: this.homeworkId!,
          request: request,
        );
        homeworkId = homework.id;
        print('✅ Homework updated with ID: $homeworkId');
      } else {
        print('📝 Creating homework...');
        final homework = await homeworkRepo.createHomework(
          groupId: groupId ?? selectedCourse.courseGroup,
          courseId: selectedCourseId!,
          request: request,
        );
        homeworkId = homework.id;
        print('✅ Homework created with ID: $homeworkId');
      }

      Navigator.of(context).pop();

      Navigator.pushNamed(
        context,
        '/assignmentReminderScreen',
        arguments: {
          'homeworkId': homeworkId,
          'groupId': groupId ?? selectedCourse.courseGroup,
          'courseId': selectedCourseId!,
          'isEditMode': isEditMode,
        },
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Color _getColorForPriority(double value) {
    // Clamp value to 1–100
    value = value.clamp(1, 100);

    // Determine bucket index (0–9)
    int index = ((value - 1) / 10).floor();

    const colors = [
      Color(0xff6FCC43), // (green)
      Color(0xff86D238),
      Color(0xffA1D72E),
      Color(0xffBEDC26),
      Color(0xffD9DF1E),
      Color(0xffF2DD19),
      Color(0xffFBC313),
      Color(0xffF79E0E),
      Color(0xffEF6A0B),
      Color(0xffD92727), // (red)
    ];

    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CourseBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchCoursesEvent()),
        ),
        BlocProvider(
          create: (context) => HomeworkBloc(
            homeworkRepository: HomeworkRepositoryImpl(
              remoteDataSource: HomeworkRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => MaterialBloc(
            materialRepository: MaterialRepositoryImpl(
              remoteDataSource: MaterialRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchMaterialGroupsEvent()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<HomeworkBloc, homework_state.HomeworkState>(
            listener: (context, state) {
              if (state is homework_state.HomeworkByIdLoaded) {
                _populateFieldsFromHomework(state.homework);
              } else if (state is homework_state.HomeworkByIdError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading homework: ${state.message}'),
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
                  _courses = state.courses;

                  // In edit mode, once courses are available, derive groupId
                  // and fetch both categories and materials for the course
                  if (isEditMode && selectedCourseId != null) {
                    try {
                      final course = _courses.firstWhere(
                        (c) => c.id == selectedCourseId,
                      );
                      groupId = course.courseGroup;

                      BlocProvider.of<CourseBloc>(context).add(
                        FetchCategoriesEvent(
                          groupId: groupId!,
                          courseId: selectedCourseId!,
                        ),
                      );

                      _fetchMaterialsForCourse(context, selectedCourseId!);
                    } catch (_) {
                      // If not found, leave as is; listeners may populate later
                    }
                  }
                });
              } else if (state is course_state.CategoriesLoaded) {
                setState(() {
                  final previousCategoryId = selectedCategoryId;
                  _categories = state.categories;
                  if (previousCategoryId != null &&
                      _categories.any((cat) => cat.id == previousCategoryId)) {
                    selectedCategoryId = previousCategoryId;
                    print('✅ Category restored: $selectedCategoryId');
                  } else if (!isEditMode) {
                    selectedCategoryId = null;
                  }
                });
              } else if (state is course_state.CategoriesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: redColor,
                  ),
                );
              }
            },
          ),
          BlocListener<MaterialBloc, material_state.MaterialState>(
            listener: (context, state) {
              if (state is material_state.MaterialGroupsLoaded) {
                setState(() {
                  _materialGroups = state.materialGroups;
                });
              } else if (state is material_state.MaterialsLoaded) {
                setState(() {
                  // Merge materials from this group with existing materials
                  final filtered = (selectedCourseId != null)
                      ? state.materials
                            .where(
                              (material) =>
                                  material.courses != null &&
                                  material.courses!.contains(selectedCourseId),
                            )
                            .toList()
                      : List.of(state.materials);

                  final Map<int, MaterialModel> byId = {
                    for (final m in _materials) m.id: m,
                  };
                  for (final m in filtered) {
                    byId[m.id] = m;
                  }
                  _materials = byId.values.toList();

                  // Do not clear previously selected IDs during incremental loads
                  print(' Materials merged: ${_materials.length}');
                });
              } else if (state is material_state.MaterialsError) {
                setState(() {
                  _materials = [];
                });
              }
            },
          ),
        ],
        child: _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext scaffoldContext) {
    return Scaffold(
      backgroundColor: softGrey,
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 12.h),
                width: double.infinity,
                decoration: BoxDecoration(color: whiteColor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.keyboard_arrow_left,
                        color: blackColor,
                        size: 24,
                      ),
                    ),
                    Text(
                      isEditMode ? 'Edit Assignment' : 'Add Assignment',
                      style: AppTextStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Assignment/Event pill toggle (hidden in edit mode)
                    if (!isEditMode)
                      _AssignmentEventToggle(
                        isEventSelected: false,
                        onChanged: (toEvent) {
                          if (toEvent) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.addEventScreen,
                            );
                          }
                        },
                      )
                    else
                      SizedBox(width: 24),
                  ],
                ),
              ),

              // Stepper
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 12.v),
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
                    finishedStepBackgroundColor: primaryColor.withOpacity(0.1),
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
                      if (index == 1) {
                        _goToReminderScreen(context);
                      }
                    },
                    steps: [
                      EasyStep(
                        customStep: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.1),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.edit_outlined,
                              color: whiteColor,
                              size: 20.adaptSize,
                            ),
                          ),
                        ),
                        customTitle: Padding(
                          padding: EdgeInsets.only(top: 8.v),
                          child: Text(
                            'Assignment',
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
                              Icons.notifications_active_outlined,
                              color: primaryColor,
                              size: 20.adaptSize,
                            ),
                          ),
                        ),
                        customTitle: Padding(
                          padding: EdgeInsets.only(top: 8.v),
                          child: Text(
                            'Reminder',
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

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Title',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.v),
                        CustomClassTextField(
                          text: '',
                          controller: _titleController,
                        ),
                        SizedBox(height: 18.v),
                        // Class Dropdown
                        Text(
                          'Class',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: isEditMode
                                ? greyColor.withOpacity(0.1)
                                : whiteColor,
                          ),
                          child: DropdownButton<int>(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: blackColor.withOpacity(0.6),
                            ),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              _courses.isEmpty
                                  ? 'Loading classes ...'
                                  : '',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedCourseId,
                            items: _courses.map((course) {
                              return DropdownMenuItem<int>(
                                value: course.id,
                                child: Text(
                                  course.title,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            // Disable course selection in edit mode
                            onChanged: (_courses.isEmpty || isEditMode)
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedCourseId = value;
                                      // Reset category and materials when course changes
                                      selectedCategoryId = null;
                                      selectedMaterialIds = [];
                                      _categories = [];
                                      _materials = [];
                                    });

                                    // Fetch categories and materials for selected course
                                    if (value != null) {
                                      final selectedCourse = _courses
                                          .firstWhere((c) => c.id == value);
                                      _selectedCourseGroupId =
                                          selectedCourse.courseGroup;

                                      BlocProvider.of<CourseBloc>(context).add(
                                        FetchCategoriesEvent(
                                          groupId: selectedCourse.courseGroup,
                                          courseId: value,
                                        ),
                                      );

                                      _fetchMaterialsForCourse(context, value);
                                    }
                                  },
                          ),
                        ),
                        SizedBox(height: 18.v),
                        // Category Dropdown
                        Text(
                          'Category',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: DropdownButton<int>(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: blackColor.withOpacity(0.6),
                            ),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              selectedCourseId == null
                                  ? ''
                                  : _categories.isEmpty
                                  ? 'No categories available'
                                  : '',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedCategoryId,
                            items: _categories.map((category) {
                              return DropdownMenuItem<int>(
                                value: category.id,
                                child: Text(
                                  category.title,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged:
                                (selectedCourseId == null ||
                                    _categories.isEmpty)
                                ? null
                                : (value) {
                                    setState(() => selectedCategoryId = value);
                                  },
                          ),
                        ),
                        SizedBox(height: 18.v),
                        // Materials
                        Text(
                          'Materials',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (selectedMaterialIds.isEmpty)
                                Text(
                                  selectedCourseId == null
                                      ? ''
                                      : _materials.isEmpty
                                      ? 'No materials available'
                                      : 'No materials selected',
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.5),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: -8,
                                  children: selectedMaterialIds.map((id) {
                                    return Chip(
                                      label: Text(
                                        _materialTitleById(id),
                                        style: AppTextStyle.eTextStyle.copyWith(
                                          color: blackColor,
                                        ),
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          selectedMaterialIds.remove(id);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              SizedBox(height: 8.v),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AbsorbPointer(
                                  absorbing:
                                      selectedCourseId == null ||
                                      _materials.isEmpty,
                                  child: Opacity(
                                    opacity:
                                        selectedCourseId == null ||
                                            _materials.isEmpty
                                        ? 0.5
                                        : 1,
                                    child: TextButton.icon(
                                      onPressed: () => _openMaterialPicker(),
                                      icon: Icon(
                                        Icons.add,
                                        color: primaryColor,
                                      ),
                                      label: Text(
                                        'Add materials',
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
                        SizedBox(height: 18.v),

                        // Schedule Section
                        Text(
                          'Schedule',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12.v),
                        // All Day + Show End (same row)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: greyColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isAllDay,
                                onChanged: (val) {
                                  setState(() => isAllDay = val ?? false);
                                },
                                activeColor: primaryColor,
                              ),
                              Text(
                                'All Day',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                              SizedBox(width: 24.h),
                              Checkbox(
                                value: isShowEndDateTime,
                                onChanged: (val) {
                                  setState(
                                    () => isShowEndDateTime = val ?? false,
                                  );
                                },
                                activeColor: primaryColor,
                              ),
                              Text(
                                'Show End',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.v),
                        // Dates in one row when Show End is enabled
                        if (isShowEndDateTime) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: blackColor.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8.v),
                                    GestureDetector(
                                      onTap: () => _selectDate(context, true),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.h,
                                          vertical: 12.v,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: blackColor.withOpacity(0.15),
                                          ),
                                          color: whiteColor,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _startDate != null
                                                  ? _formatDateForDisplay(
                                                      _startDate!,
                                                    )
                                                  : '',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: _startDate != null
                                                        ? blackColor
                                                        : blackColor
                                                              .withOpacity(0.5),
                                                  ),
                                            ),
                                            Icon(
                                              Icons.calendar_today,
                                              color: primaryColor,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.h),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: blackColor.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8.v),
                                    GestureDetector(
                                      onTap: () => _selectDate(context, false),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.h,
                                          vertical: 12.v,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: blackColor.withOpacity(0.15),
                                          ),
                                          color: whiteColor,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _endDate != null
                                                  ? _formatDateForDisplay(
                                                      _endDate!,
                                                    )
                                                  : 'Select End Date',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: _endDate != null
                                                        ? blackColor
                                                        : blackColor
                                                              .withOpacity(0.5),
                                                  ),
                                            ),
                                            Icon(
                                              Icons.calendar_today,
                                              color: primaryColor,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'Start Date',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.h,
                                vertical: 12.v,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: blackColor.withOpacity(0.15),
                                ),
                                color: whiteColor,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startDate != null
                                        ? _formatDateForDisplay(_startDate!)
                                        : '',
                                    style: AppTextStyle.eTextStyle.copyWith(
                                      color: _startDate != null
                                          ? blackColor
                                          : blackColor.withOpacity(0.5),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (!isAllDay) ...[
                          SizedBox(height: 16.v),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '',
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: blackColor.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8.v),
                                    GestureDetector(
                                      onTap: () => _selectTime(context, true),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.h,
                                          vertical: 12.v,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: blackColor.withOpacity(0.15),
                                          ),
                                          color: whiteColor,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _startTime != null
                                                  ? _formatTime(_startTime!)
                                                  : '',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: _startTime != null
                                                        ? blackColor
                                                        : blackColor
                                                              .withOpacity(0.5),
                                                  ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              color: primaryColor,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isShowEndDateTime) ...[
                                SizedBox(width: 12.h),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Time',
                                        style: AppTextStyle.eTextStyle.copyWith(
                                          color: blackColor.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8.v),
                                      GestureDetector(
                                        onTap: () =>
                                            _selectTime(context, false),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.h,
                                            vertical: 12.v,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: blackColor.withOpacity(
                                                0.15,
                                              ),
                                            ),
                                            color: whiteColor,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _endTime != null
                                                    ? _formatTime(_endTime!)
                                                    : 'End Time',
                                                style: AppTextStyle.eTextStyle
                                                    .copyWith(
                                                      color: _endTime != null
                                                          ? blackColor
                                                          : blackColor
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                    ),
                                              ),
                                              Icon(
                                                Icons.access_time,
                                                color: primaryColor,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        SizedBox(height: 12.v),
                        // Priority Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Priority',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.h,
                                vertical: 6.v,
                              ),
                              child: Text(
                                '${(_priorityValue / 10).round()}',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: _getColorForPriority(_priorityValue),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.v),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _getColorForPriority(_priorityValue),
                            inactiveTrackColor: greyColor.withOpacity(0.3),
                            thumbColor: _getColorForPriority(_priorityValue),
                            overlayColor:
                                (_getColorForPriority(_priorityValue))
                                    .withOpacity(0.2),
                            showValueIndicator: ShowValueIndicator.never,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 12.0,
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 20.0,
                            ),
                            trackHeight: 6.0,
                          ),
                          child: Slider(
                            value: _priorityValue,
                            min: 0,
                            max: 100,
                            divisions: 10,
                            label: '${_priorityValue.round()}',
                            onChanged: (value) {
                              setState(() {
                                _priorityValue = value;
                              });
                            },
                          ),
                        ),

                        SizedBox(height: 18.v),
                        // Completed Checkbox
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: greyColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isCompleted,
                                onChanged: (val) {
                                  setState(() {
                                    isCompleted = val ?? false;
                                    // When unchecked, set grade to -1/100 as per backend requirement
                                    if (!isCompleted) {
                                      _gradeController.text = '-1/100';
                                    } else if (_gradeController.text.trim() ==
                                        '-1/100') {
                                      // Clear the -1/100 when checking completed
                                      _gradeController.clear();
                                    }
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text(
                                'Completed',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Grade Field (conditional)
                        if (isCompleted) ...[
                          SizedBox(height: 12.v),
                          Text(
                            'Grade',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: blackColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          CustomClassTextField(
                            text: 'Enter Grade',
                            controller: _gradeController,
                          ),
                        ],
                        SizedBox(height: 24.v),
                        // Details Section
                        Text(
                          'Details',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12.v),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: TextFormField(
                            controller: _detailsController,
                            maxLines: 6,
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: blackColor,
                            ),
                            decoration: InputDecoration(
                              hintText: '',
                              hintStyle: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12.v,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32.v),
                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: CustomTextButton(
                            buttonText: 'Save',
                            onPressed: () => _goToReminderScreen(context),
                          ),
                        ),
                        SizedBox(height: 20.v),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentEventToggle extends StatelessWidget {
  final bool isEventSelected;
  final ValueChanged<bool> onChanged;

  const _AssignmentEventToggle({
    required this.isEventSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = softGrey;
    final Color accent = primaryColor;
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            context: context,
            label: 'Assignment',
            selected: !isEventSelected,
            onTap: () => onChanged(false),
          ),
          _segment(
            context: context,
            label: 'Event',
            selected: isEventSelected,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
        decoration: BoxDecoration(
          color: selected ? primaryColor : transparentColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyle.eTextStyle.copyWith(
            color: selected ? whiteColor : blackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
