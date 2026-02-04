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
import 'package:heliumapp/presentation/widgets/shadow_container.dart';
import 'package:heliumapp/utils/app_style.dart';

enum CourseAddSteps {
  details('Details', Icons.list),
  schedule('Schedule', Icons.calendar_month),
  categories('Categories', Icons.category),
  attachments('Attachments', Icons.attachment);

  final String label;
  final IconData icon;

  const CourseAddSteps(this.label, this.icon);
}

class CourseStepper extends StatelessWidget {
  final int selectedIndex;
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;
  final bool Function()? onStep;

  const CourseStepper({
    super.key,
    required this.selectedIndex,
    required this.courseGroupId,
    this.courseId,
    required this.isEdit,
    this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        child: EasyStepper(
          lineStyle: LineStyle(
            // FIXME: with new fonts, this needs to be reduced further
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
          stepRadius: 24,
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

    final courseBloc = context.read<CourseBloc>();
    final args = CourseAddArgs(
      courseBloc: courseBloc,
      courseGroupId: courseGroupId,
      courseId: courseId,
      isEdit: isEdit,
    );

    if (index == CourseAddSteps.details.index) {
      context.pushReplacement(AppRoutes.courseAddScreen, extra: args);
      return;
    }

    if (index == CourseAddSteps.schedule.index) {
      context.pushReplacement(AppRoutes.courseAddScheduleScreen, extra: args);
    }

    if (index == CourseAddSteps.categories.index) {
      context.pushReplacement(AppRoutes.courseAddCategoriesScreen, extra: args);
    }

    if (index == CourseAddSteps.attachments.index) {
      context.pushReplacement(
        AppRoutes.courseAddAttachmentsScreen,
        extra: args,
      );
    }
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
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CourseAddSteps.details.label,
            style: selectedIndex == CourseAddSteps.details.index
                ? AppStyles.menuItemActive(context)
                : AppStyles.menuItem(context),
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
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CourseAddSteps.schedule.label,
            style: selectedIndex == CourseAddSteps.schedule.index
                ? AppStyles.menuItemActive(context)
                : AppStyles.menuItem(context).copyWith(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
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
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CourseAddSteps.categories.label,
            style: selectedIndex == CourseAddSteps.categories.index
                ? AppStyles.menuItemActive(context)
                : AppStyles.menuItem(context).copyWith(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
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
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CourseAddSteps.attachments.label,
            style: selectedIndex == CourseAddSteps.attachments.index
                ? AppStyles.menuItemActive(context)
                : AppStyles.menuItem(context).copyWith(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
                  ),
          ),
        ),
      ),
    ];
  }
}
