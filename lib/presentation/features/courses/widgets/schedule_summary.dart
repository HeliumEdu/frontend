// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/presentation/features/courses/constants/schedule_constants.dart';
import 'package:heliumapp/presentation/ui/components/pill_badge.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// The meeting-pattern summary for a [CourseScheduleModel], shared by the
/// schedule editor list and the courses-screen class cards: an optional
/// date-range row, an optional rotation label, then one day-pill row per
/// meeting time. Callers supply their own chrome; [selectable] makes the
/// times/dates copyable.
class ScheduleSummary extends StatelessWidget {
  final CourseScheduleModel schedule;
  final Color color;
  final bool selectable;

  const ScheduleSummary({
    super.key,
    required this.schedule,
    required this.color,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final groups = schedule.groupsByTime().entries.toList();
    if (groups.isEmpty) {
      return Text('No meeting days', style: AppStyles.formLabel(context));
    }

    final dateRange = schedule.overrideDateRangeLabel();
    final rotationLabel = ScheduleTemplate.summaryLabel(schedule);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dateRange != null) ...[
          _buildIconRow(context, Icons.date_range_outlined, dateRange),
          const SizedBox(height: 10),
        ],
        if (rotationLabel != null) ...[
          _buildIconRow(context, Icons.autorenew, rotationLabel),
          const SizedBox(height: 8),
        ],
        for (int i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildTimeGroup(context, groups[i].value, groups[i].key),
        ],
      ],
    );
  }

  Widget _buildTimeGroup(
    BuildContext context,
    List<String> days,
    String timeRange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: days
              .map((day) => PillBadge(text: day, color: color))
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildIconRow(context, Icons.access_time, timeRange),
      ],
    );
  }

  Widget _buildIconRow(BuildContext context, IconData icon, String label) {
    final onSurface = context.colorScheme.onSurface;
    final textStyle = AppStyles.standardBodyText(context).copyWith(
      color: onSurface.withValues(alpha: 0.6),
    );
    return Row(
      children: [
        Icon(
          icon,
          size: Responsive.getIconSize(
            context,
            mobile: 14,
            tablet: 16,
            desktop: 18,
          ),
          color: onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: selectable
              ? SelectableText(label, style: textStyle)
              : Text(label, style: textStyle),
        ),
      ],
    );
  }
}
