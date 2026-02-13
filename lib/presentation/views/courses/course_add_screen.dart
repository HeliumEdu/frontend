// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_state.dart';
import 'package:heliumapp/presentation/views/core/multi_step_container.dart';
import 'package:heliumapp/presentation/widgets/courses/course_attachments_widget.dart';
import 'package:heliumapp/presentation/widgets/courses/course_categories_widget.dart';
import 'package:heliumapp/presentation/widgets/courses/course_details_widget.dart';
import 'package:heliumapp/presentation/widgets/courses/course_schedule_widget.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows course add/edit as a dialog on desktop, or navigates on mobile
void showCourseAdd(
  BuildContext context, {
  required int courseGroupId,
  int? courseId,
  required bool isEdit,
  required bool isNew,
  int initialStep = 0,
  CourseBloc? courseBloc,
}) {
  // FIXME: not sure we have a path where we ever pass this through the args, I think we always pull it from the context, so might be able to clean this function params and logic up (and on all other pages)
  final bloc = courseBloc ?? context.read<CourseBloc>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoutes.courseAddScreen,
      extra: CourseAddArgs(
        courseBloc: bloc,
        courseGroupId: courseGroupId,
        courseId: courseId,
        isEdit: isEdit,
        isNew: isNew,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      child: BlocProvider<CourseBloc>.value(
        value: bloc,
        child: CourseAddScreen(
          courseGroupId: courseGroupId,
          courseId: courseId,
          isEdit: isEdit,
          isNew: isNew,
          initialStep: initialStep,
        ),
      ),
      width: AppConstants.centeredDialogWidth,
      alignment: Alignment.center,
    );
  }
}

class CourseAddScreen extends MultiStepContainer {
  final int courseGroupId;
  final int? courseId;

  const CourseAddScreen({
    super.key,
    required this.courseGroupId,
    this.courseId,
    required super.isEdit,
    required super.isNew,
    super.initialStep = 0,
  });

  @override
  State<CourseAddScreen> createState() => _CourseAddScreenState();
}

class _CourseAddScreenState extends MultiStepContainerState<CourseAddScreen> {
  final _detailsKey = GlobalKey<CourseDetailsWidgetState>();
  final _scheduleKey = GlobalKey<CourseScheduleWidgetState>();

  // State
  int? _currentCourseId;
  int? _targetStep;

  @override
  void initState() {
    super.initState();
    _currentCourseId = widget.courseId;
  }

  @override
  bool get enableNextSteps => _currentCourseId != null;

  @override
  void onStepRequested(int step) {
    if (step == currentStep) return;

    if (saveAction != null) {
      _targetStep = step;
      saveAction!();

      // BlocListener will handle state transition after save
      return;
    }

    navigateToStep(step);
  }

  @override
  String get screenTitle => !widget.isNew ? 'Edit Class' : 'Add Class';

  @override
  IconData? get icon => Icons.school;

  @override
  Function? get saveAction {
    if (steps[currentStep].stepScreenType != ScreenType.entityPage) {
      return null;
    }
    // Return function that evaluates widget state when called, not when getter runs
    return () {
      Function? widgetSubmit;
      switch (currentStep) {
        case 0:
          widgetSubmit = _detailsKey.currentState?.onSubmit;
          break;
        case 1:
          widgetSubmit = _scheduleKey.currentState?.onSubmit;
          break;
      }
      if (widgetSubmit != null) {
        setState(() => isSubmitting = true);
        widgetSubmit();
      }
    };
  }

  void _navigateAfterSave() {
    if (_targetStep != null) {
      // User explicitly requested a specific step (clicked step icon)
      final step = _targetStep!;
      _targetStep = null;
      if (step < steps.length) {
        navigateToStep(step);
      } else {
        cancelAction();
      }
    } else if (widget.isNew && currentStep + 1 < steps.length) {
      // In create mode, auto-advance to next step
      navigateToStep(currentStep + 1);
    } else {
      cancelAction();
    }
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesError) {
            showSnackBar(context, state.message!, isError: true);
            setState(() => isSubmitting = false);
          } else if (state is CourseCreated || state is CourseUpdated) {
            state as CourseEntityState;

            showSnackBar(context, 'Class saved');

            setState(() {
              _currentCourseId = state.course.id;
              isSubmitting = false;
            });

            _navigateAfterSave();
          } else if (state is CourseScheduleUpdated) {
            showSnackBar(context, 'Class schedule saved');
            setState(() => isSubmitting = false);

            _navigateAfterSave();
          }
        },
      ),
    ];
  }

  late final List<MultiStepDefinition> _steps = [
    MultiStepDefinition(
      icon: Icons.list,
      tooltip: 'Details',
      stepScreenType: ScreenType.entityPage,
      builder: (context) => CourseDetailsWidget(
        key: _detailsKey,
        courseGroupId: widget.courseGroupId,
        courseId: _currentCourseId,
        isEdit: widget.isEdit || _currentCourseId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
      ),
    ),
    MultiStepDefinition(
      icon: Icons.date_range_outlined,
      tooltip: 'Schedule',
      stepScreenType: ScreenType.entityPage,
      builder: (context) => CourseScheduleWidget(
        key: _scheduleKey,
        courseGroupId: widget.courseGroupId,
        courseId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
      ),
    ),
    MultiStepDefinition(
      icon: Icons.category,
      tooltip: 'Categories',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CourseCategoriesWidget(
        courseGroupId: widget.courseGroupId,
        courseId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
      ),
    ),
    MultiStepDefinition(
      icon: Icons.attachment,
      tooltip: 'Attachments',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CourseAttachmentsWidget(
        courseGroupId: widget.courseGroupId,
        entityId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        userSettings: userSettings,
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}
