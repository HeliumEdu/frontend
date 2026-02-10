// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';
import 'package:heliumapp/presentation/widgets/calendar_item_add_stepper.dart';

/// Container that manages the calendar item add stepper flow in dialog mode.
///
/// When displayed as a dialog, this widget handles step navigation internally
/// by swapping screens. When not in dialog mode, each screen handles its own
/// navigation using GoRouter.
class CalendarItemStepperContainer extends DialogStepperContainer {
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;
  final bool isNew;

  const CalendarItemStepperContainer({
    super.key,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required this.isEdit,
    required this.isNew,
    super.initialStep = 0,
  });

  @override
  Widget buildStepWidget(BuildContext context, int stepIndex) {
    return CalendarItemAddSteps.values[stepIndex].buildWidget(
      eventId: eventId,
      homeworkId: homeworkId,
      initialDate: initialDate,
      isFromMonthView: isFromMonthView,
      isEdit: isEdit,
      isNew: isNew,
    );
  }
}
