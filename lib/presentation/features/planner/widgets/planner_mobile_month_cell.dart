import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PlannerMobileMonthCell extends StatelessWidget {
  final MonthCellDetails details;
  final UserSettingsModel userSettings;

  const PlannerMobileMonthCell({
    super.key,
    required this.details,
    required this.userSettings,
  });

  @override
  Widget build(BuildContext context) {
    // Device clock: SfCalendar anchors its own today on a bare DateTime.now(),
    // so zoning this would paint a second, disagreeing marker.
    final isToday = DateUtils.isSameDay(details.date, DateTime.now());
    final isCurrentMonth =
        details.visibleDates.isNotEmpty &&
        details.date.month == details.visibleDates[15].month;

    // Determine which types are present for this date
    final items = details.appointments.cast<PlannerItemBaseModel>();
    final hasEvents = items.any((item) => item is EventModel);
    final hasHomework = items.any((item) => item is HomeworkModel);
    final hasClassSchedules = items.any(
      (item) => item is CourseScheduleEventModel,
    );
    final hasExternalCalendars = items.any(
      (item) => item is ExternalCalendarEventModel,
    );

    // Build indicator dots for present types
    final indicatorColors = <Color>[
      if (hasHomework) PlannerTypeColors.homework,
      if (hasEvents) userSettings.eventsColor,
      if (hasClassSchedules) PlannerTypeColors.classSchedules,
      if (hasExternalCalendars) PlannerTypeColors.externalCalendars,
    ];

    final borderColor = context.colorScheme.outline.withValues(alpha: 0.3);
    final dateIndex = details.visibleDates.indexOf(details.date);
    final isLastRow = dateIndex >= details.visibleDates.length - 7;

    return CustomPaint(
      foregroundPainter: _MobileCellBorderPainter(
        color: borderColor,
        drawBottom: isLastRow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Container(
            width: 26,
            height: 26,
            decoration: isToday
                ? BoxDecoration(
                    color: context.colorScheme.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              details.date.day.toString(),
              style: AppStyles.smallSecondaryText(context).copyWith(
                color: isToday
                    ? context.colorScheme.onPrimary
                    : isCurrentMonth
                    ? context.colorScheme.onSurface
                    : context.colorScheme.onSurface.withValues(
                        alpha: AppStyles.mutedTextAlpha,
                      ),
                fontWeight: isToday ? FontWeight.w600 : null,
              ),
            ),
          ),
          const Spacer(),
          if (indicatorColors.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: details.bounds.height * 0.14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: indicatorColors
                    .map(
                      (color) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileCellBorderPainter extends CustomPainter {
  const _MobileCellBorderPainter({
    required this.color,
    required this.drawBottom,
  });

  final Color color;
  final bool drawBottom;

  static const _stroke = 0.5;
  static const _half = _stroke / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;

    // Top: full width.
    canvas.drawLine(const Offset(0, _half), Offset(size.width, _half), paint);

    // Right: starts at _stroke (just below the top line) to avoid painting
    // the corner pixel twice, which would double the alpha and create a
    // visible bright dot at every cell intersection.
    canvas.drawLine(
      Offset(size.width - _half, _stroke),
      Offset(
        size.width - _half,
        drawBottom ? size.height - _stroke : size.height,
      ),
      paint,
    );

    if (drawBottom) {
      canvas.drawLine(
        Offset(0, size.height - _half),
        Offset(size.width, size.height - _half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MobileCellBorderPainter old) =>
      old.color != color || old.drawBottom != drawBottom;
}
