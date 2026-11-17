import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_calendar_tile.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_meta_row.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

class PlannerItemTooltip extends StatelessWidget {
  static const _tooltipWaitDuration = Duration(milliseconds: 500);
  static const _tooltipShowDuration = Duration(seconds: 8);

  final PlannerItemBaseModel plannerItem;
  final Widget child;
  final bool isInAgendaStyle;
  final bool isSuppressed;
  final UserSettingsModel userSettings;
  final PlannerItemDataSource? plannerItemDataSource;
  final List<CourseModel> courses;
  final Map<int, CategoryModel> categoriesMap;
  final Map<int, ExternalCalendarModel> externalCalendarsById;

  const PlannerItemTooltip({
    super.key,
    required this.plannerItem,
    required this.child,
    this.isInAgendaStyle = false,
    required this.isSuppressed,
    required this.userSettings,
    required this.plannerItemDataSource,
    required this.courses,
    required this.categoriesMap,
    required this.externalCalendarsById,
  });

  @override
  Widget build(BuildContext context) {
    if (isSuppressed ||
        !PlatformBehavior.showsHoverTooltips ||
        !userSettings.showPlannerTooltips) {
      return child;
    }

    if (isInAgendaStyle &&
        plannerItem is! HomeworkModel &&
        plannerItem is! EventModel) {
      return child;
    }

    final tooltipMessage = _buildPlannerItemTooltipMessage(
      context,
      plannerItem,
    );
    if (tooltipMessage == null) {
      return child;
    }

    return Tooltip(
      richMessage: tooltipMessage,
      waitDuration: _tooltipWaitDuration,
      showDuration: _tooltipShowDuration,
      preferBelow: false,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );
  }

  InlineSpan? _buildPlannerItemTooltipMessage(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
  ) {
    final titleStyle = AppStyles.formText(context).copyWith(
      color: context.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = AppStyles.formText(
      context,
    ).copyWith(color: context.colorScheme.onSurface);
    final mutedIconColor = context.colorScheme.onSurface.withValues(
      alpha: 0.75,
    );
    final whenIcon = PlannerItemCalendarTile.isRecurring(plannerItem)
        ? Icons.repeat
        : Icons.access_time;
    final rows = <_PlannerTooltipRow>[];
    final isOnline =
        plannerItemDataSource?.isOnlineForItem(plannerItem) ?? false;
    final location = plannerItemDataSource?.getLocationForItem(plannerItem);

    if (isOnline) {
      rows.add(
        const _PlannerTooltipRow.text(icon: Icons.language, text: 'Online'),
      );
    } else if (location != null && location.isNotEmpty) {
      rows.add(
        _PlannerTooltipRow.text(icon: Icons.pin_drop_outlined, text: location),
      );
    }

    if (plannerItem is HomeworkModel) {
      final course = courses.firstWhereOrNull(
        (c) => c.id == plannerItem.course.id,
      );
      final categoryTitle =
          plannerItem.category.entity?.title ??
          categoriesMap[plannerItem.category.id]?.title;

      if (course != null) {
        rows.add(
          _PlannerTooltipRow.text(
            icon: Icons.school_outlined,
            text: course.title,
            color: course.color,
          ),
        );
      }
      if (categoryTitle != null && categoryTitle.isNotEmpty) {
        rows.add(
          _PlannerTooltipRow.text(
            icon: Icons.category_outlined,
            text: categoryTitle,
            color: categoriesMap[plannerItem.category.id]?.color,
          ),
        );
      }
      if (plannerItemDataSource!.isHomeworkCompleted(plannerItem) &&
          GradeHelper.parseGrade(plannerItem.currentGrade) != null) {
        rows.add(
          _PlannerTooltipRow.text(
            icon: Icons.assignment_turned_in_outlined,
            text: GradeHelper.gradeForDisplay(plannerItem.currentGrade),
            color: context.colorScheme.primary,
          ),
        );
      }
    } else if (plannerItem is EventModel) {
      rows.add(
        _PlannerTooltipRow.text(
          icon: Icons.source_outlined,
          text: 'Source: Events',
          color: userSettings.eventsColor,
        ),
      );
    } else if (plannerItem is ExternalCalendarEventModel) {
      final calendarId = int.tryParse(plannerItem.ownerId);
      final externalCalendar = calendarId != null
          ? externalCalendarsById[calendarId]
          : null;
      rows.add(
        _PlannerTooltipRow.text(
          icon: Icons.source_outlined,
          text: 'Source: ${externalCalendar?.title ?? 'External Calendar'}',
          color: externalCalendar?.color ?? plannerItem.color,
        ),
      );
    }

    if (PlannerItemMetaRow.hasAny(
      plannerItem,
      pulledThroughAttachmentCount: _pulledThroughAttachmentCount(plannerItem),
      resourceCount: _visibleResources(plannerItem).length,
      includeRecurrence: false,
    )) {
      rows.add(
        _PlannerTooltipRow.widget(
          widget: Container(
            width: 50,
            height: 1,
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      );
      rows.add(
        _PlannerTooltipRow.widget(
          widget: _buildTooltipMetaCountsRow(context, plannerItem),
        ),
      );
    }

    final typeIcon = plannerItem is HomeworkModel
        ? AppConstants.assignmentIcon
        : plannerItem is EventModel
        ? AppConstants.eventIcon
        : plannerItem is CourseScheduleEventModel
        ? AppConstants.courseScheduleIcon
        : AppConstants.externalCalendarIcon;
    final typeIconColor = plannerItem is CourseScheduleEventModel
        ? plannerItem.color
        : mutedIconColor;

    final children = <InlineSpan>[
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(typeIcon, size: 14, color: typeIconColor),
      ),
      const TextSpan(text: ' '),
      TextSpan(text: plannerItem.title, style: titleStyle),
      const TextSpan(text: '\n'),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          width: 50,
          height: 1,
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      const TextSpan(text: '\n'),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(whenIcon, size: 14, color: mutedIconColor),
      ),
      TextSpan(
        text: ' ${_buildTooltipWhenLine(plannerItem)}',
        style: bodyStyle,
      ),
    ];

    children.addAll(_buildTooltipRowSpans(rows, bodyStyle, mutedIconColor));

    return TextSpan(children: children);
  }

  List<InlineSpan> _buildTooltipRowSpans(
    List<_PlannerTooltipRow> rows,
    TextStyle bodyStyle,
    Color mutedIconColor,
  ) {
    if (rows.isEmpty) return [];

    final spans = <InlineSpan>[const TextSpan(text: '\n')];
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.widget != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: row.widget!,
          ),
        );
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              row.icon!,
              size: 14,
              color: row.color ?? mutedIconColor,
            ),
          ),
        );
        spans.add(TextSpan(text: ' ${row.text}', style: bodyStyle));
      }
      if (i != rows.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  String _buildTooltipWhenLine(PlannerItemBaseModel plannerItem) {
    final localStart = HeliumDateTime.toLocal(
      plannerItem.start,
      userSettings.timeZone,
    );
    final localEnd = HeliumDateTime.toLocal(
      plannerItem.end,
      userSettings.timeZone,
    );
    return HeliumDateTime.formatDateTimeRange(
      localStart,
      localEnd,
      plannerItem.showEndTime,
      plannerItem.allDay,
    );
  }

  int _pulledThroughAttachmentCount(PlannerItemBaseModel plannerItem) {
    if (plannerItem is! HomeworkModel) return 0;
    return plannerItemDataSource?.pulledThroughAttachmentCount(plannerItem) ??
        0;
  }

  List<ResourceModel> _visibleResources(PlannerItemBaseModel plannerItem) {
    if (plannerItem is! HomeworkModel) return const [];
    return plannerItemDataSource?.visibleResourcesFor(plannerItem) ?? const [];
  }

  Widget _buildTooltipMetaCountsRow(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
  ) {
    return PlannerItemMetaRow(
      plannerItem: plannerItem,
      userSettings: userSettings,
      pulledThroughAttachmentCount: _pulledThroughAttachmentCount(plannerItem),
      resources: _visibleResources(plannerItem),
      countTextStyle: AppStyles.formText(
        context,
      ).copyWith(color: context.colorScheme.onSurface),
      maxEntries: null,
      showRecurrence: false,
    );
  }
}

class _PlannerTooltipRow {
  final IconData? icon;
  final String? text;
  final Color? color;
  final Widget? widget;

  const _PlannerTooltipRow.text({
    required this.icon,
    required this.text,
    this.color,
  }) : widget = null;

  const _PlannerTooltipRow.widget({required this.widget})
    : icon = null,
      text = null,
      color = null;
}
