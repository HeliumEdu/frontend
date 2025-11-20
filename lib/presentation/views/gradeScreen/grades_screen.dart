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
import 'package:heliumedu/data/datasources/grade_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/course_group_response_model.dart';
import 'package:heliumedu/data/repositories/course_repository_impl.dart';
import 'package:heliumedu/data/repositories/grade_repository_impl.dart';
// Removed Auth-related imports as logout functionality is moved to settings
import 'package:heliumedu/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart';
import 'package:heliumedu/presentation/bloc/gradeBloc/grade_bloc.dart';
import 'package:heliumedu/presentation/bloc/gradeBloc/grade_event.dart';
import 'package:heliumedu/presentation/bloc/gradeBloc/grade_state.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  int? expandedIndex;
  int selectedGroupIndex = 0; // Default to first course group
  bool _initializedGroup = false; // ensure we preselect only once
  Map<int, CourseGroupResponseModel> _courseGroupsMap =
      {}; // Store course groups by ID for date lookup

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GradeBloc(
            gradeRepository: GradeRepositoryImpl(
              remoteDataSource: GradeRemoteDataSourceImpl(dioClient: dioClient),
            ),
          )..add(FetchGradesEvent()),
        ),
        BlocProvider(
          create: (context) => CourseBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: dioClient,
              ),
            ),
          )..add(FetchCourseGroupsEvent()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CourseBloc, CourseState>(
            listener: (context, state) {
              if (state is CourseGroupsLoaded) {
                setState(() {
                  _courseGroupsMap = {
                    for (var group in state.courseGroups) group.id: group,
                  };
                });
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: softGrey,
          body: SafeArea(
            child: BlocBuilder<GradeBloc, GradeState>(
              builder: (context, state) {
                if (state is GradeLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                    ),
                  );
                }

                if (state is GradeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.h),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GradeBloc>().add(FetchGradesEvent());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.h,
                              vertical: 12.v,
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: whiteColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is GradeLoaded) {
                  final courseGroups = state.courseGroups;

                  if (courseGroups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grade_outlined,
                            size: 60,
                            color: textColor.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No grades available',
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Ensure selected index is valid and preselect latest group once
                  if (!_initializedGroup && courseGroups.isNotEmpty) {
                    int maxId = courseGroups.first.id;
                    int maxIdx = 0;
                    for (int i = 1; i < courseGroups.length; i++) {
                      if (courseGroups[i].id > maxId) {
                        maxId = courseGroups[i].id;
                        maxIdx = i;
                      }
                    }
                    selectedGroupIndex = maxIdx;
                    _initializedGroup = true;
                  } else if (selectedGroupIndex >= courseGroups.length) {
                    selectedGroupIndex = 0;
                  }

                  final selectedGroup = courseGroups[selectedGroupIndex];
                  final courses = selectedGroup.courses;

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.v,
                          horizontal: 16.h,
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
                              'Grades',
                              style: AppTextStyle.bTextStyle.copyWith(
                                color: blackColor,
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

                      // Scrollable Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Dropdown (reuse Classes style)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButton<String>(
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
                                  value: courseGroups.isEmpty
                                      ? null
                                      : courseGroups[selectedGroupIndex].title,
                                  items: courseGroups
                                      .map(
                                        (group) => DropdownMenuItem(
                                          value: group.title,
                                          child: Text(
                                            group.title,
                                            style: AppTextStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withOpacity(
                                                    0.8,
                                                  ),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final idx = courseGroups.indexWhere(
                                      (g) => g.title == value,
                                    );
                                    if (idx == -1) return;
                                    setState(() {
                                      selectedGroupIndex = idx;
                                      expandedIndex = null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 16.v),
                              Container(
                                padding: EdgeInsets.all(20.adaptSize),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withOpacity(0.7),
                                      primaryColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    20.adaptSize,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 24.v),

                                    // Grades Grid - Real API Data
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: 4,
                                      // 4 summary cards
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12.h,
                                            mainAxisSpacing: 12.v,
                                            childAspectRatio: 1.3,
                                          ),
                                      itemBuilder: (context, index) {
                                        // Calculate real metrics from API data
                                        final totalGraded =
                                            selectedGroup.totalGradedHomework;
                                        final totalCourses =
                                            selectedGroup.courses.length;
                                        final totalAssignments = selectedGroup
                                            .courses
                                            .fold(
                                              0,
                                              (sum, course) =>
                                                  sum +
                                                  course.numHomeworkGraded,
                                            );

                                        // Calculate completion percentage
                                        final completedAssignments =
                                            selectedGroup.courses
                                                .where(
                                                  (course) => course.hasGrade,
                                                )
                                                .length;
                                        final completionPercentage =
                                            totalCourses > 0
                                            ? (completedAssignments /
                                                      totalCourses *
                                                      100)
                                                  .round()
                                            : 0;

                                        // Build summary cards based on index
                                        Widget cardContent;
                                        switch (index) {
                                          case 0: // "complete" card
                                            cardContent = Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 40.adaptSize,
                                                  height: 40.adaptSize,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: whiteColor
                                                        .withOpacity(0.2),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Center(
                                                        child: Text(
                                                          '$completionPercentage%',
                                                          style: AppTextStyle
                                                              .aTextStyle
                                                              .copyWith(
                                                                color:
                                                                    whiteColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 8.v),
                                                Text(
                                                  '$completedAssignments complete',
                                                  style: AppTextStyle.cTextStyle
                                                      .copyWith(
                                                        color: whiteColor
                                                            .withOpacity(0.9),
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ],
                                            );
                                          case 1: // "through term" card
                                            // Get dates from course group if grade model dates are empty
                                            String startDate =
                                                selectedGroup.startDate;
                                            String endDate =
                                                selectedGroup.endDate;

                                            // If dates are empty, try to get from course groups map
                                            if ((startDate.isEmpty ||
                                                    endDate.isEmpty) &&
                                                _courseGroupsMap.containsKey(
                                                  selectedGroup.id,
                                                )) {
                                              final courseGroup =
                                                  _courseGroupsMap[selectedGroup
                                                      .id]!;
                                              startDate = courseGroup.startDate;
                                              endDate = courseGroup.endDate;
                                            }

                                            final thruTermPercentage =
                                                _calculateThruTermPercentage(
                                                  startDate: startDate,
                                                  endDate: endDate,
                                                );
                                            cardContent = Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 40.adaptSize,
                                                  height: 40.adaptSize,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: whiteColor
                                                        .withOpacity(0.2),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Center(
                                                        child: Text(
                                                          '$thruTermPercentage%',
                                                          style: AppTextStyle
                                                              .aTextStyle
                                                              .copyWith(
                                                                color:
                                                                    whiteColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 8.v),
                                                Text(
                                                  'through term',
                                                  style: AppTextStyle.cTextStyle
                                                      .copyWith(
                                                        color: whiteColor
                                                            .withOpacity(0.9),
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ],
                                            );
                                            break;

                                          case 2: // "assignments" card
                                            cardContent = Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$totalAssignments',
                                                      style: AppTextStyle
                                                          .aTextStyle
                                                          .copyWith(
                                                            color: whiteColor,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 20,
                                                          ),
                                                    ),
                                                    Text(
                                                      'total assignments',
                                                      style: AppTextStyle
                                                          .cTextStyle
                                                          .copyWith(
                                                            color: whiteColor
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            fontSize: 11,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                            break;

                                          case 3: // "graded" card
                                            cardContent = Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,

                                              children: [
                                                SizedBox(width: 8.h),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$totalGraded',
                                                      style: AppTextStyle
                                                          .aTextStyle
                                                          .copyWith(
                                                            color: whiteColor,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 20,
                                                          ),
                                                    ),
                                                    Text(
                                                      'graded',
                                                      style: AppTextStyle
                                                          .cTextStyle
                                                          .copyWith(
                                                            color: whiteColor
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            fontSize: 11,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                            break;

                                          default:
                                            cardContent = SizedBox.shrink();
                                        }

                                        return Container(
                                          padding: EdgeInsets.all(12.adaptSize),
                                          decoration: BoxDecoration(
                                            color: whiteColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              16.adaptSize,
                                            ),
                                            border: Border.all(
                                              color: whiteColor.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: cardContent,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.v),

                              // Courses List
                              ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final course = courses[index];
                                  final isExpanded = expandedIndex == index;

                                  // Parse color from hex string
                                  Color courseColor = primaryColor;
                                  try {
                                    final colorValue = int.parse(
                                      course.color.replaceFirst('#', 'FF'),
                                      radix: 16,
                                    );
                                    courseColor = Color(colorValue);
                                  } catch (e) {
                                    courseColor = primaryColor;
                                  }

                                  return Column(
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (expandedIndex == index) {
                                                expandedIndex = null;
                                              } else {
                                                expandedIndex = index;
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(
                                            16.adaptSize,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              16.adaptSize,
                                            ),
                                            decoration: BoxDecoration(
                                              color: whiteColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    16.adaptSize,
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(
                                                    14.adaptSize,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: courseColor
                                                        .withOpacity(0.15),
                                                  ),
                                                  child: Icon(
                                                    Icons.book_outlined,
                                                    color: courseColor,
                                                    size: 24.adaptSize,
                                                  ),
                                                ),
                                                SizedBox(width: 14.h),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        course.title,
                                                        style: AppTextStyle
                                                            .bTextStyle
                                                            .copyWith(
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      SizedBox(height: 4.v),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      8.h,
                                                                  vertical: 2.v,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: courseColor
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6.adaptSize,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              course
                                                                  .formattedGrade,
                                                              style: AppTextStyle
                                                                  .cTextStyle
                                                                  .copyWith(
                                                                    color:
                                                                        courseColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                            ),
                                                          ),
                                                          if (course.trend !=
                                                              null) ...[
                                                            SizedBox(
                                                              width: 4.h,
                                                            ),
                                                            Icon(
                                                              course.trend! > 0
                                                                  ? Icons
                                                                        .trending_up
                                                                  : course.trend! <
                                                                        0
                                                                  ? Icons
                                                                        .trending_down
                                                                  : Icons
                                                                        .trending_flat,
                                                              size:
                                                                  14.adaptSize,
                                                              color:
                                                                  course.trend! >
                                                                      0
                                                                  ? Colors.green
                                                                  : course.trend! <
                                                                        0
                                                                  ? Colors.red
                                                                  : textColor
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                            ),
                                                          ],
                                                          SizedBox(width: 8.h),
                                                          Icon(
                                                            Icons.circle,
                                                            size: 6.adaptSize,
                                                            color: textColor
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                          ),
                                                          SizedBox(width: 8.h),
                                                          Text(
                                                            '${course.numHomeworkGraded} Graded',
                                                            style: AppTextStyle
                                                                .cTextStyle
                                                                .copyWith(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                        0.6,
                                                                      ),
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                AnimatedRotation(
                                                  turns: isExpanded ? 0.5 : 0,
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      8.adaptSize,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: softGrey,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.adaptSize,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.keyboard_arrow_down,
                                                      color: textColor,
                                                      size: 20.adaptSize,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      AnimatedSize(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child:
                                            isExpanded &&
                                                course.categories.isNotEmpty
                                            ? Container(
                                                margin: EdgeInsets.only(
                                                  top: 8.v,
                                                ),
                                                padding: EdgeInsets.all(
                                                  16.adaptSize,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: whiteColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.adaptSize,
                                                      ),
                                                  border: Border.all(
                                                    color: courseColor
                                                        .withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    // Header Row
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12.h,
                                                            vertical: 12.v,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: courseColor
                                                            .withOpacity(0.05),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.adaptSize,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 2,
                                                            child: Text(
                                                              'Category',
                                                              style: AppTextStyle
                                                                  .cTextStyle
                                                                  .copyWith(
                                                                    color:
                                                                        textColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Text(
                                                              'Graded',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: AppTextStyle
                                                                  .cTextStyle
                                                                  .copyWith(
                                                                    color:
                                                                        textColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Text(
                                                              'Average',
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: AppTextStyle
                                                                  .cTextStyle
                                                                  .copyWith(
                                                                    color:
                                                                        textColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    SizedBox(height: 8.v),

                                                    // Categories from API
                                                    ListView.separated(
                                                      shrinkWrap: true,
                                                      physics:
                                                          NeverScrollableScrollPhysics(),
                                                      itemCount: course
                                                          .categories
                                                          .length,
                                                      itemBuilder: (context, catIndex) {
                                                        final category = course
                                                            .categories[catIndex];

                                                        // Parse category color
                                                        Color categoryColor =
                                                            courseColor;
                                                        try {
                                                          final catColorValue =
                                                              int.parse(
                                                                category.color
                                                                    .replaceFirst(
                                                                      '#',
                                                                      'FF',
                                                                    ),
                                                                radix: 16,
                                                              );
                                                          categoryColor = Color(
                                                            catColorValue,
                                                          );
                                                        } catch (e) {
                                                          categoryColor =
                                                              courseColor;
                                                        }

                                                        return Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    12.h,
                                                                vertical: 10.v,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 2,
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      width: 6
                                                                          .adaptSize,
                                                                      height: 6
                                                                          .adaptSize,
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            categoryColor,
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          8.h,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        category
                                                                            .title,
                                                                        style: AppTextStyle.cTextStyle.copyWith(
                                                                          color:
                                                                              textColor,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: Text(
                                                                  '${category.numHomeworkGraded} of ${category.numHomework}',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: AppTextStyle
                                                                      .cTextStyle
                                                                      .copyWith(
                                                                        color: textColor
                                                                            .withOpacity(
                                                                              0.7,
                                                                            ),
                                                                      ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: Text(
                                                                  category
                                                                      .formattedGrade,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .right,
                                                                  style: AppTextStyle
                                                                      .cTextStyle
                                                                      .copyWith(
                                                                        color: textColor
                                                                            .withOpacity(
                                                                              0.7,
                                                                            ),
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                      separatorBuilder:
                                                          (context, catIndex) {
                                                            return Divider(
                                                              height: 1,
                                                              indent: 12.h,
                                                              endIndent: 12.h,
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                            );
                                                          },
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : SizedBox.shrink(),
                                      ),
                                    ],
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return SizedBox(height: 12.v);
                                },
                                itemCount: courses.length,
                              ),

                              SizedBox(height: 24.v),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    valueColor: AlwaysStoppedAnimation(whiteColor),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Calculate percentage of days completed through the term
  // Returns 0-100 representing how far through the term we are
  int _calculateThruTermPercentage({
    required String startDate,
    required String endDate,
  }) {
    if (startDate.isEmpty || endDate.isEmpty) {
      return 0;
    }

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final now = DateTime.now();

      // If before start date, return 0%
      if (now.isBefore(start)) {
        return 0;
      }

      // If after end date, return 100%
      if (now.isAfter(end)) {
        return 100;
      }

      // Calculate percentage
      final totalDays = end.difference(start).inDays;
      if (totalDays <= 0) {
        return 0;
      }

      final daysElapsed = now.difference(start).inDays;
      final percentage = (daysElapsed / totalDays * 100).round();

      // Clamp between 0 and 100
      if (percentage < 0) return 0;
      if (percentage > 100) return 100;
      return percentage;
    } catch (e) {
      // If date parsing fails, return 0
      return 0;
    }
  }
}
