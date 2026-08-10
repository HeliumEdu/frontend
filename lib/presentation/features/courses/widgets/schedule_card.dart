// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/presentation/features/courses/widgets/schedule_summary.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/layout/mobile_gesture_detector.dart';
import 'package:heliumapp/utils/planner_helper.dart';

/// Summary card for a [CourseScheduleModel] in the schedule list: tap or edit to
/// edit, trailing action to delete. Days/times render via [ScheduleSummary].
class ScheduleCard extends StatelessWidget {
  final CourseScheduleModel schedule;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return MobileGestureDetector(
      onTap: onEdit,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ScheduleSummary(schedule: schedule, color: color),
              ),
              const SizedBox(width: 8),
              if (PlannerHelper.shouldShowEditButton(context)) ...[
                Semantics(
                  label: 'Edit',
                  button: true,
                  child: HeliumIconButton(onPressed: onEdit, icon: Icons.edit_outlined),
                ),
                const SizedBox(width: 8),
              ],
              Semantics(
                label: 'Delete',
                button: true,
                child: HeliumIconButton(
                  onPressed: onDelete,
                  icon: Icons.delete_outline,
                  color: context.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
