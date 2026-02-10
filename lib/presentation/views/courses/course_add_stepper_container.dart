// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';
import 'package:heliumapp/presentation/widgets/course_add_stepper.dart';

class CourseAddStepperContainer extends DialogStepperContainer {
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;
  final bool isNew;

  const CourseAddStepperContainer({
    super.key,
    required this.courseGroupId,
    this.courseId,
    required this.isEdit,
    required this.isNew,
    super.initialStep = 0,
  });

  @override
  Widget buildStepWidget(BuildContext context, int stepIndex) {
    return CourseAddSteps.values[stepIndex].buildWidget(
      courseGroupId: courseGroupId,
      courseId: courseId,
      isEdit: isEdit,
      isNew: isNew,
    );
  }
}
