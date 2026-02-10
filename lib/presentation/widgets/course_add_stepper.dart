// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';
import 'package:heliumapp/presentation/views/courses/course_add_attachment_screen.dart'
    show CourseAddAttachmentScreen;
import 'package:heliumapp/presentation/views/courses/course_add_category_screen.dart'
    show CourseAddCategoryScreen;
import 'package:heliumapp/presentation/views/courses/course_add_schedule_screen.dart'
    show CourseAddScheduleProvidedScreen;
import 'package:heliumapp/presentation/views/courses/course_add_screen.dart'
    show CourseAddProvidedScreen;
import 'package:heliumapp/presentation/widgets/shadow_container.dart';

// FIXME: in dialog mode, the stepper icons look too small

enum CourseAddSteps {
  details(Icons.list, AppRoutes.courseAddScreen),
  schedule(Icons.date_range_outlined, AppRoutes.courseAddScheduleScreen),
  categories(Icons.category, AppRoutes.courseAddCategoriesScreen),
  attachments(Icons.attachment, AppRoutes.courseAddAttachmentsScreen);

  final IconData icon;
  final String route;

  const CourseAddSteps(this.icon, this.route);

  Widget buildWidget({
    required int courseGroupId,
    int? courseId,
    required bool isEdit,
    required bool isNew,
  }) {
    switch (this) {
      case CourseAddSteps.details:
        return CourseAddProvidedScreen(
          courseGroupId: courseGroupId,
          courseId: courseId,
          isEdit: isEdit,
          isNew: isNew
        );
      case CourseAddSteps.schedule:
        return CourseAddScheduleProvidedScreen(
          courseGroupId: courseGroupId,
          courseId: courseId!,
          isEdit: isEdit,
          isNew: isNew,
        );
      case CourseAddSteps.categories:
        return CourseAddCategoryScreen(
          courseGroupId: courseGroupId,
          courseId: courseId!,
          isEdit: isEdit,
          isNew: isNew,
        );
      case CourseAddSteps.attachments:
        return CourseAddAttachmentScreen(
          courseGroupId: courseGroupId,
          entityId: courseId!,
          isEdit: isEdit,
          isNew: isNew,
        );
    }
  }
}

class CourseStepper extends StatelessWidget {
  final int selectedIndex;
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;
  final bool isNew;
  final bool Function()? onStep;

  const CourseStepper({
    super.key,
    required this.selectedIndex,
    required this.courseGroupId,
    this.courseId,
    required this.isEdit,
    required this.isNew,
    this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        child: EasyStepper(
          showTitle: false,
          lineStyle: LineStyle(
            lineLength: (MediaQuery.sizeOf(context).width - 275) / 4,
            lineThickness: 3,
            lineSpace: 4,
            lineType: LineType.normal,
            defaultLineColor: context.colorScheme.outline.withValues(
              alpha: 0.1,
            ),
            finishedLineColor: context.colorScheme.primary,
            activeLineColor: context.colorScheme.primary.withValues(alpha: 0.5),
          ),
          activeStepIconColor: context.colorScheme.surface,
          activeStepTextColor: context.colorScheme.primary,
          finishedStepBorderColor: context.colorScheme.primary,
          finishedStepBackgroundColor: context.colorScheme.primary.withValues(
            alpha: 0.1,
          ),
          finishedStepIconColor: context.colorScheme.primary,
          unreachedStepBorderColor: context.colorScheme.outline.withValues(
            alpha: 0.1,
          ),
          unreachedStepBackgroundColor: Theme.of(
            context,
          ).scaffoldBackgroundColor,
          unreachedStepIconColor: context.colorScheme.outline,
          unreachedStepTextColor: context.colorScheme.onSurface.withValues(
            alpha: 0.1,
          ),
          internalPadding: 12,
          showLoadingAnimation: false,
          stepRadius: 30,
          showStepBorder: true,
          disableScroll: true,
          activeStep: selectedIndex,
          onStepReached: (index) => _onStepReached(context, index),
          steps: _buildSteps(context),
        ),
      ),
    );
  }

  void _onStepReached(BuildContext context, int index) {
    if (index == selectedIndex) return;

    if (onStep != null && !onStep!.call()) {
      return;
    }

    // Try to navigate within dialog first
    if (_navigateToStepInDialog(context, index)) {
      return;
    }

    // Fall back to router navigation for non-dialog mode
    final step = CourseAddSteps.values[index];
    final courseBloc = context.read<CourseBloc>();
    final args = CourseAddArgs(
      courseBloc: courseBloc,
      courseGroupId: courseGroupId,
      courseId: courseId,
      isEdit: isEdit,
      isNew: isNew
    );

    context.pushReplacement(step.route, extra: args);
  }

  /// Helper function to navigate to a step when in dialog mode.
  /// Returns true if navigation was handled (dialog mode), false otherwise.
  bool _navigateToStepInDialog(BuildContext context, int stepIndex) {
    return navigateStepInDialog(context, stepIndex);
  }

  List<EasyStep> _buildSteps(BuildContext context) {
    return [
      EasyStep(
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CourseAddSteps.details.index ? 1 : 0.1,
            ),
            border: Border.all(color: context.colorScheme.primary, width: 2),
          ),
          child: Center(
            child: Icon(
              CourseAddSteps.details.icon,
              color: selectedIndex == CourseAddSteps.details.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
      EasyStep(
        enabled: isEdit,
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CourseAddSteps.schedule.index ? 1 : 0.1,
            ),
            border: Border.all(
              color: context.colorScheme.primary.withValues(
                alpha: isEdit ? 1 : 0.3,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              CourseAddSteps.schedule.icon,
              color: selectedIndex == CourseAddSteps.schedule.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
              size: 20,
            ),
          ),
        ),
      ),
      EasyStep(
        enabled: isEdit,
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CourseAddSteps.categories.index ? 1 : 0.1,
            ),
            border: Border.all(
              color: context.colorScheme.primary.withValues(
                alpha: isEdit ? 1 : 0.3,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              CourseAddSteps.categories.icon,
              color: selectedIndex == CourseAddSteps.categories.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
              size: 20,
            ),
          ),
        ),
      ),
      EasyStep(
        enabled: isEdit,
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CourseAddSteps.attachments.index
                  ? 1
                  : 0.1,
            ),
            border: Border.all(
              color: context.colorScheme.primary.withValues(
                alpha: isEdit ? 1 : 0.3,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              CourseAddSteps.attachments.icon,
              color: selectedIndex == CourseAddSteps.attachments.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
              size: 20,
            ),
          ),
        ),
      ),
    ];
  }
}
