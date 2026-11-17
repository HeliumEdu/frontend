import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/planner_month_layout.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/standalone.dart' as tz;

class PlannerItemCalendarTile extends StatelessWidget {
  static const String checkboxKeyPrefix = 'planner_item_checkbox_';
  static const agendaHeightMobile = 53.0;
  static const agendaHeightDesktop = 57.0;
  static const _calendarItemIconSize = 10.0;
  static const _calendarItemIconGap = 2.0;

  final PlannerItemBaseModel plannerItem;
  final double width;
  final double? height;
  final bool isInAgenda;
  final bool? completedOverride;
  final DateTime? occurrenceDate;
  final PlannerItemDataSource? plannerItemDataSource;
  final PlannerView currentView;
  final tz.Location timeZone;
  final List<CourseModel> courses;
  final bool Function(
    PlannerItemBaseModel plannerItem, {
    DateTime? occurrenceDate,
    bool? hideWebsiteLink,
  })
  onOpenPlannerItem;
  final void Function(
    HomeworkModel homework,
    bool value, {
    DateTime? occurrenceDate,
  })
  onToggleCompleted;

  const PlannerItemCalendarTile({
    super.key,
    required this.plannerItem,
    required this.width,
    this.height,
    required this.isInAgenda,
    this.completedOverride,
    this.occurrenceDate,
    required this.plannerItemDataSource,
    required this.currentView,
    required this.timeZone,
    required this.courses,
    required this.onOpenPlannerItem,
    required this.onToggleCompleted,
  });

  static bool isRecurring(PlannerItemBaseModel plannerItem) {
    return (plannerItem is CourseScheduleEventModel ||
            plannerItem is EventModel ||
            plannerItem is HomeworkModel) &&
        plannerItem.recurrenceRule != null;
  }

  @override
  Widget build(BuildContext context) {
    if (isInAgenda) {
      return _buildCalendarItemWidgetForAgenda(
        context,
        plannerItem: plannerItem,
        width: width,
        completedOverride: completedOverride,
        occurrenceDate: occurrenceDate,
      );
    } else {
      return _buildCalendarItemWidgetForTimeline(
        context,
        plannerItem: plannerItem,
        width: width,
        height: height,
        completedOverride: completedOverride,
        occurrenceDate: occurrenceDate,
      );
    }
  }

  Widget? _buildItemIcon(
    BuildContext context, {
    required PlannerItemBaseModel plannerItem,
    required double appointmentWidth,
    bool? completedOverride,
    required Color backgroundColor,
    bool isInAgenda = false,
    bool checkboxHandlesTaps = true,
    DateTime? occurrenceDate,
  }) {
    if (PlannerHelper.shouldShowCheckbox(plannerItem, appointmentWidth)) {
      return _buildCheckboxWidget(
        context,
        homework: plannerItem as HomeworkModel,
        completedOverride: completedOverride,
        occurrenceDate: occurrenceDate,
        backgroundColor: backgroundColor,
        handlesTaps: checkboxHandlesTaps,
      );
    } else if (PlannerHelper.shouldShowSchoolIcon(
      context,
      plannerItem,
      currentView,
    )) {
      return _buildPrefixIconWidget(
        context,
        AppConstants.courseScheduleIcon,
        backgroundColor: backgroundColor,
      );
    } else if (isInAgenda && plannerItem is ExternalCalendarEventModel) {
      return _buildPrefixIconWidget(
        context,
        AppConstants.externalCalendarIcon,
        backgroundColor: backgroundColor,
      );
    } else if (isInAgenda && plannerItem is EventModel) {
      return _buildPrefixIconWidget(
        context,
        AppConstants.eventIcon,
        backgroundColor: backgroundColor,
      );
    }
    return null;
  }

  Widget _buildCalendarItemCenterForAgenda(
    BuildContext context, {
    required PlannerItemBaseModel plannerItem,
    bool isOnline = false,
    String? location,
    bool? completedOverride,
    required Color backgroundColor,
    bool wrapInExpanded = true,
  }) {
    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarItemTitle(
          context,
          plannerItem,
          isInAgenda: true,
          completedOverride: completedOverride,
          backgroundColor: backgroundColor,
        ),
        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          plannerItem,
          true,
          currentView,
        ))
          _buildCalendarItemTimeBelowTitleRow(
            context,
            plannerItem,
            isInAgenda: true,
            backgroundColor: backgroundColor,
          ),
        if (PlannerHelper.shouldShowLocationBelowTitle(
          context,
          plannerItem,
          true,
          currentView,
        ))
          if (isOnline)
            _buildCalendarItemOnlineRow(
              context,
              isInAgenda: true,
              backgroundColor: backgroundColor,
            )
          else if (location != null && location.isNotEmpty)
            _buildCalendarItemLocationRow(
              context,
              location,
              isInAgenda: true,
              backgroundColor: backgroundColor,
            ),
      ],
    );

    final paddedContent = Padding(
      padding: _recurringContentPadding(plannerItem),
      child: contentColumn,
    );

    if (wrapInExpanded) {
      return Expanded(child: paddedContent);
    }
    return paddedContent;
  }

  Widget _buildCalendarItemCenterForTimeline(
    BuildContext context, {
    required PlannerItemBaseModel plannerItem,
    bool isOnline = false,
    String? location,
    Widget? inlineIcon,
    bool? completedOverride,
    required Color backgroundColor,
  }) {
    final showTimeBeforeTitle = PlannerHelper.shouldShowTimeBeforeTitle(
      context,
      plannerItem,
      false,
      currentView,
    );

    final foregroundColor = backgroundColor.contrasting;

    Widget titleRowWidget;
    if (inlineIcon != null || showTimeBeforeTitle) {
      // Build the title row inside a ListenableBuilder so the strikethrough
      // reacts to the same changeNotifier signal as the checkbox. Otherwise
      // the strikethrough is frozen at appointmentBuilder call time and lags
      // the checkbox on rapid toggles.
      Widget buildTitleRich(bool isCompleted) {
        final spans = <InlineSpan>[];

        if (inlineIcon != null) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(
                  top: currentView == PlannerView.month ? 0 : 1,
                  right: 4,
                ),
                child: inlineIcon,
              ),
            ),
          );
        }

        if (showTimeBeforeTitle) {
          spans.add(
            _buildCalendarItemTimeSpan(
              context,
              plannerItem,
              backgroundColor: backgroundColor,
            ),
          );
          spans.add(const TextSpan(text: ' ', semanticsLabel: ''));
        }

        // Labelled on the span, not the Text, so the inline checkbox keeps its
        // own accessibility node.
        spans.add(
          TextSpan(
            text: plannerItem.title.characters.join('\u200B'),
            semanticsLabel: plannerItem.title,
            style: AppStyles.calendarItemText(context).copyWith(
              color: foregroundColor,
              decoration: isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: foregroundColor,
            ),
          ),
        );

        return Text.rich(
          TextSpan(children: spans),
          style: AppStyles.calendarItemText(
            context,
          ).copyWith(color: foregroundColor),
          maxLines: currentView == PlannerView.month || plannerItem.allDay
              ? 1
              : null,
          overflow: currentView == PlannerView.month || plannerItem.allDay
              ? TextOverflow.ellipsis
              : null,
        );
      }

      if (plannerItem is HomeworkModel && plannerItemDataSource != null) {
        final dataSource = plannerItemDataSource!;
        titleRowWidget = ListenableBuilder(
          listenable: dataSource.changeNotifier,
          builder: (context, _) =>
              buildTitleRich(dataSource.isHomeworkCompleted(plannerItem)),
        );
      } else {
        final isCompleted =
            completedOverride ??
            (plannerItem is HomeworkModel && plannerItem.completed);
        titleRowWidget = buildTitleRich(isCompleted);
      }
    } else {
      titleRowWidget = _buildCalendarItemTitle(
        context,
        plannerItem,
        isInAgenda: false,
        completedOverride: completedOverride,
        backgroundColor: backgroundColor,
      );
    }

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRowWidget,
        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          plannerItem,
          false,
          currentView,
        ))
          _buildCalendarItemTimeBelowTitleRow(
            context,
            plannerItem,
            isInAgenda: false,
            backgroundColor: backgroundColor,
          ),
        if (PlannerHelper.shouldShowLocationBelowTitle(
          context,
          plannerItem,
          false,
          currentView,
        ))
          if (isOnline)
            _buildCalendarItemOnlineRow(
              context,
              isInAgenda: false,
              backgroundColor: backgroundColor,
            )
          else if (location != null && location.isNotEmpty)
            _buildCalendarItemLocationRow(
              context,
              location,
              isInAgenda: false,
              backgroundColor: backgroundColor,
            ),
      ],
    );

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: _recurringContentPadding(plannerItem),
        child: contentColumn,
      ),
    );
  }

  Widget _buildCalendarItemRight(
    BuildContext context, {
    required PlannerItemBaseModel plannerItem,
    CourseModel? course,
    required Color backgroundColor,
    DateTime? occurrenceDate,
  }) {
    final foregroundColor = backgroundColor.contrasting;
    final buttons = <Widget>[];

    if (course?.teacherEmail.isNotEmpty ?? false) {
      buttons.add(
        HeliumIconButton(
          onPressed: () {
            UrlHelpers.launchMailUrl(course!.teacherEmail);
          },
          icon: Icons.email_outlined,
          tooltip: 'Email teacher',
          color: foregroundColor,
        ),
      );
    }

    if (course?.website != null) {
      buttons.add(
        HeliumIconButton(
          onPressed: () {
            UrlHelpers.launchWebUrl(course!.website.toString());
          },
          icon: Icons.launch_outlined,
          tooltip: 'Launch class website',
          color: foregroundColor,
        ),
      );
    }

    if (plannerItem is CourseScheduleEventModel &&
        PlatformBehavior.showItemActions(context)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => onOpenPlannerItem(
            plannerItem,
            occurrenceDate: occurrenceDate,
            hideWebsiteLink: true,
          ),
          icon: Icons.more_vert,
          semanticLabel: 'More',
          color: foregroundColor,
        ),
      );
    }

    if (PlannerHelper.shouldShowEditButtonForPlannerItem(
      context,
      plannerItem,
    )) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => onOpenPlannerItem(plannerItem),
          icon: Icons.edit_outlined,
          semanticLabel: 'Edit',
          color: foregroundColor,
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i < buttons.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildAgendaLeftContent(Widget icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: icon),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAgendaLeftTapZone({
    required Widget icon,
    required double height,
    required VoidCallback onTap,
    bool excludeFromSemantics = false,
  }) {
    return MergeSemantics(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: excludeFromSemantics,
          onTap: onTap,
          child: SizedBox(height: height, child: _buildAgendaLeftContent(icon)),
        ),
      ),
    );
  }

  Widget _buildCalendarItemWidgetForAgenda(
    BuildContext context, {
    required PlannerItemBaseModel plannerItem,
    required double width,
    bool? completedOverride,
    DateTime? occurrenceDate,
  }) {
    final color = plannerItemDataSource!.getColorForItem(plannerItem);
    final isOnline = plannerItemDataSource!.isOnlineForItem(plannerItem);
    final location = plannerItemDataSource!.getLocationForItem(plannerItem);
    final course = _getCourseForPlannerItem(plannerItem);

    final leftIcon = _buildItemIcon(
      context,
      plannerItem: plannerItem,
      appointmentWidth: width,
      completedOverride: completedOverride,
      backgroundColor: color,
      isInAgenda: true,
      occurrenceDate: occurrenceDate,
    );

    final centerWidget = _buildCalendarItemCenterForAgenda(
      context,
      plannerItem: plannerItem,
      isOnline: isOnline,
      location: location,
      completedOverride: completedOverride,
      backgroundColor: color,
    );

    final rightWidget = PrintHidden(
      child: _buildCalendarItemRight(
        context,
        plannerItem: plannerItem,
        course: course,
        backgroundColor: color,
        occurrenceDate: occurrenceDate,
      ),
    );

    final agendaHeight = Responsive.isMobile(context)
        ? agendaHeightMobile
        : agendaHeightDesktop;

    final isCheckbox =
        plannerItem is HomeworkModel &&
        PlannerHelper.shouldShowCheckbox(plannerItem, width);
    final useTouchTargets = PlatformBehavior.usesTouchTargets;

    final Widget leftColumn;
    if (leftIcon == null) {
      leftColumn = const SizedBox(width: 8);
    } else if (useTouchTargets && isCheckbox) {
      // IgnorePointer so only the column GestureDetector handles taps,
      // preventing double-toggle from both handlers firing
      leftColumn = _buildAgendaLeftTapZone(
        icon: IgnorePointer(child: leftIcon),
        height: agendaHeight,
        onTap: () {
          // Fetch current value at tap time, not build time, to avoid
          // stale closures on rapid taps
          final currentValue = plannerItemDataSource!.isHomeworkCompleted(
            plannerItem,
          );
          onToggleCompleted(
            plannerItem,
            !currentValue,
            occurrenceDate: occurrenceDate,
          );
        },
      );
    } else if (PlannerHelper.shouldOpenOnItemTap(context)) {
      leftColumn = _buildAgendaLeftTapZone(
        icon: leftIcon,
        height: agendaHeight,
        excludeFromSemantics: true,
        onTap: () {
          Feedback.forTap(context);
          onOpenPlannerItem(plannerItem, occurrenceDate: occurrenceDate);
        },
      );
    } else {
      leftColumn = _buildAgendaLeftContent(leftIcon);
    }

    Widget centerColumn;
    if (PlannerHelper.shouldOpenOnItemTap(context)) {
      final centerContent = _buildCalendarItemCenterForAgenda(
        context,
        plannerItem: plannerItem,
        isOnline: isOnline,
        location: location,
        completedOverride: completedOverride,
        backgroundColor: color,
        wrapInExpanded: false,
      );
      centerColumn = Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Feedback.forTap(context);
            onOpenPlannerItem(plannerItem, occurrenceDate: occurrenceDate);
          },
          child: SizedBox(
            height: agendaHeight,
            child: Align(alignment: Alignment.centerLeft, child: centerContent),
          ),
        ),
      );
    } else {
      centerColumn = centerWidget;
    }

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: agendaHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leftColumn,
          centerColumn,
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(right: 8), child: rightWidget),
        ],
      ),
    );
  }

  Widget _buildCalendarItemWidgetForTimeline(
    BuildContext context, {
    required PlannerItemBaseModel plannerItem,
    required double width,
    double? height,
    bool? completedOverride,
    DateTime? occurrenceDate,
  }) {
    final color = plannerItemDataSource!.getColorForItem(plannerItem);
    final isOnline = plannerItemDataSource!.isOnlineForItem(plannerItem);
    final location = plannerItemDataSource!.getLocationForItem(plannerItem);

    // On touch the item's own detector owns checkbox taps, so the recognizer
    // survives the SfCalendar rebuild that a toggle triggers.
    final usesCheckboxZone =
        PlatformBehavior.usesTouchTargets &&
        PlannerHelper.shouldShowCheckbox(plannerItem, width);

    final inlineIcon = _buildItemIcon(
      context,
      plannerItem: plannerItem,
      appointmentWidth: width,
      completedOverride: completedOverride,
      backgroundColor: color,
      checkboxHandlesTaps: !usesCheckboxZone,
      occurrenceDate: occurrenceDate,
    );

    final centerWidget = _buildCalendarItemCenterForTimeline(
      context,
      plannerItem: plannerItem,
      isOnline: isOnline,
      location: location,
      inlineIcon: inlineIcon,
      completedOverride: completedOverride,
      backgroundColor: color,
    );

    Offset? timelineTapPosition;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: usesCheckboxZone ? (_) => timelineTapPosition = null : null,
      onTapUp: usesCheckboxZone
          ? (details) => timelineTapPosition = details.localPosition
          : null,
      onTapCancel: usesCheckboxZone ? () => timelineTapPosition = null : null,
      onTap: () => _onTimelineItemTap(
        context,
        position: timelineTapPosition,
        plannerItem: plannerItem,
        occurrenceDate: occurrenceDate,
        usesCheckboxZone: usesCheckboxZone,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.hardEdge,
        child: _buildRecurringIndicatorOverlay(
          plannerItem: plannerItem,
          backgroundColor: color,
          child: UnconstrainedBox(
            constrainedAxis: Axis.horizontal,
            alignment: PlannerHelper.getAlignmentForView(
              context,
              false,
              currentView,
            ),
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: centerWidget,
            ),
          ),
        ),
      ),
    );
  }

  // A semantics tap carries no position and opens the item.
  bool _isCheckboxZoneTap(Offset? position) {
    if (position == null) {
      return false;
    }

    const zone = PlannerHelper.checkboxWidth * 1.5;
    return position.dx < zone && position.dy < zone;
  }

  void _onTimelineItemTap(
    BuildContext context, {
    required Offset? position,
    required PlannerItemBaseModel plannerItem,
    required DateTime? occurrenceDate,
    required bool usesCheckboxZone,
  }) {
    if (usesCheckboxZone && _isCheckboxZoneTap(position)) {
      final homework = plannerItem as HomeworkModel;
      final currentValue = plannerItemDataSource!.isHomeworkCompleted(homework);
      onToggleCompleted(
        homework,
        !currentValue,
        occurrenceDate: occurrenceDate,
      );
      return;
    }

    Feedback.forTap(context);
    onOpenPlannerItem(plannerItem, occurrenceDate: occurrenceDate);
  }

  CourseModel? _getCourseForPlannerItem(PlannerItemBaseModel plannerItem) {
    if (plannerItem is HomeworkModel) {
      return courses.firstWhereOrNull((c) => c.id == plannerItem.course.id);
    } else if (plannerItem is CourseScheduleEventModel) {
      return courses.firstWhereOrNull(
        (c) => c.id.toString() == plannerItem.ownerId,
      );
    }
    return null;
  }

  Widget _buildCalendarItemTitle(
    BuildContext context,
    PlannerItemBaseModel plannerItem, {
    required bool isInAgenda,
    bool? completedOverride,
    required Color backgroundColor,
  }) {
    Widget buildTitle(bool isCompleted) {
      final foregroundColor = backgroundColor.contrasting;
      final baseStyle = isInAgenda
          ? AppStyles.smallSecondaryTextLight(context)
          : AppStyles.calendarItemText(context);
      final titleStyle = baseStyle.copyWith(
        color: foregroundColor,
        decoration: isCompleted
            ? TextDecoration.lineThrough
            : TextDecoration.none,
        decorationColor: foregroundColor,
      );

      return Text(
        isInAgenda
            ? plannerItem.title
            : plannerItem.title.characters.join('\u200B'),
        style: titleStyle,
        maxLines:
            currentView == PlannerView.month ||
                currentView == PlannerView.agenda
            ? 1
            : null,
        overflow:
            currentView == PlannerView.month ||
                currentView == PlannerView.agenda
            ? TextOverflow.ellipsis
            : null,
        semanticsLabel: isInAgenda ? null : plannerItem.title,
      );
    }

    // For homework, rebuild on data source change so strikethrough stays in
    // sync with the checkbox under rapid completion toggles.
    if (plannerItem is HomeworkModel && plannerItemDataSource != null) {
      final dataSource = plannerItemDataSource!;
      return ListenableBuilder(
        listenable: dataSource.changeNotifier,
        builder: (context, _) =>
            buildTitle(dataSource.isHomeworkCompleted(plannerItem)),
      );
    }

    return buildTitle(
      plannerItem is HomeworkModel
          ? (completedOverride ?? plannerItem.completed)
          : false,
    );
  }

  Widget _buildRecurringIndicatorIcon({required Color backgroundColor}) {
    final foregroundColor = backgroundColor.contrasting;
    return Icon(
      Icons.repeat,
      size: 12,
      color: foregroundColor.withValues(
        alpha: AppStyles.increasedContrastAlpha(0.75),
      ),
    );
  }

  Widget _buildRecurringIndicatorOverlay({
    required PlannerItemBaseModel plannerItem,
    required Widget child,
    required Color backgroundColor,
  }) {
    if (!isRecurring(plannerItem) ||
        currentView == PlannerView.agenda ||
        currentView == PlannerView.week ||
        currentView == PlannerView.day) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: IgnorePointer(
                child: _buildRecurringIndicatorIcon(
                  backgroundColor: backgroundColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  EdgeInsets _recurringContentPadding(PlannerItemBaseModel plannerItem) {
    if (!isRecurring(plannerItem)) {
      return EdgeInsets.zero;
    }

    if (currentView == PlannerView.agenda ||
        currentView == PlannerView.week ||
        currentView == PlannerView.day) {
      return EdgeInsets.zero;
    }

    return const EdgeInsets.only(right: 11);
  }

  /// With [handlesTaps] false, taps fall through to the enclosing item, which
  /// routes them, while assistive technologies can still toggle it.
  Widget _buildCheckboxWidget(
    BuildContext context, {
    required HomeworkModel homework,
    bool? completedOverride,
    required Color backgroundColor,
    bool handlesTaps = true,
    DateTime? occurrenceDate,
  }) {
    final foregroundColor = backgroundColor.contrasting;
    final primary = context.colorScheme.primary;
    final onPrimary = context.colorScheme.onPrimary;
    final dataSource = plannerItemDataSource;

    Widget buildBox(bool isCompleted) {
      return Semantics(
        container: true,
        checked: isCompleted,
        label: 'Complete ${homework.title}',
        onTap: () => _toggleHomeworkCompleted(
          homework,
          completedOverride,
          occurrenceDate,
        ),
        child: SizedBox(
          width: PlannerHelper.checkboxWidth,
          height: PlannerHelper.checkboxWidth,
          child: Transform.scale(
            scale: AppStyles.calendarItemPrefixScale(context),
            child: Container(
              decoration: BoxDecoration(
                color: isCompleted ? primary : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? primary
                      : foregroundColor.withValues(
                          alpha: AppStyles.increasedContrastAlpha(0.7),
                        ),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCompleted
                  ? Center(
                      child: Transform.translate(
                        offset: const Offset(-1.5, -1.5),
                        child: Icon(
                          Icons.check,
                          size: 17,
                          weight: 700,
                          color: onPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      key: ValueKey('$checkboxKeyPrefix${homework.id}'),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: handlesTaps
            ? () => _toggleHomeworkCompleted(
                homework,
                completedOverride,
                occurrenceDate,
              )
            : null,
        child: dataSource != null
            ? ListenableBuilder(
                listenable: dataSource.changeNotifier,
                builder: (context, _) {
                  final isCompleted = dataSource.isHomeworkCompleted(homework);
                  return buildBox(isCompleted);
                },
              )
            : buildBox(completedOverride ?? homework.completed),
      ),
    );
  }

  void _toggleHomeworkCompleted(
    HomeworkModel homework,
    bool? completedOverride,
    DateTime? occurrenceDate,
  ) {
    final current =
        plannerItemDataSource?.isHomeworkCompleted(homework) ??
        completedOverride ??
        homework.completed;
    onToggleCompleted(homework, !current, occurrenceDate: occurrenceDate);
  }

  Widget _buildPrefixIconWidget(
    BuildContext context,
    IconData icon, {
    required Color backgroundColor,
  }) {
    final foregroundColor = backgroundColor.contrasting;
    return SizedBox(
      width: PlannerHelper.checkboxWidth,
      height: PlannerHelper.checkboxWidth,
      child: Transform.scale(
        scale: AppStyles.calendarItemPrefixScale(context),
        child: Icon(
          icon,
          size: PlannerHelper.checkboxWidth,
          color: foregroundColor.withValues(
            alpha: AppStyles.increasedContrastAlpha(0.7),
          ),
        ),
      ),
    );
  }

  /// Returns an [InlineSpan] for use inside the
  /// title's [Text.rich]. Returning a [TextSpan] (rather than a [WidgetSpan]
  /// holding a [Text]) lets the paragraph ellipsizer truncate the time
  /// character-by-character when space is tight, instead of dropping the
  /// entire placeholder and collapsing the line to "...".
  InlineSpan _buildCalendarItemTimeSpan(
    BuildContext context,
    PlannerItemBaseModel plannerItem, {
    required Color backgroundColor,
  }) {
    final foregroundColor = backgroundColor.contrasting;
    final timeStyle = AppStyles.calendarItemTextLight(context).copyWith(
      color: foregroundColor.withValues(
        alpha: AppStyles.increasedContrastAlpha(0.7),
      ),
    );
    final timeSpan = TextSpan(
      text: HeliumDateTime.formatTime(
        HeliumDateTime.toLocal(plannerItem.start, timeZone),
      ),
      semanticsLabel: '',
      style: timeStyle,
    );

    if (!_shouldShowRecurringIconWithTime(plannerItem, isInAgenda: false)) {
      return timeSpan;
    }

    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _buildRecurringTimePrefixIcon(
            backgroundColor: backgroundColor,
          ),
        ),
        const TextSpan(text: ' ', semanticsLabel: ''),
        timeSpan,
      ],
    );
  }

  Widget _buildCalendarItemTimeBelowTitleRow(
    BuildContext context,
    PlannerItemBaseModel plannerItem, {
    bool isInAgenda = false,
    required Color backgroundColor,
  }) {
    final foregroundColor = backgroundColor.contrasting;
    return Row(
      children: [
        if (_shouldShowRecurringIconWithTime(
          plannerItem,
          isInAgenda: isInAgenda,
        )) ...[
          _buildRecurringTimePrefixIcon(backgroundColor: backgroundColor),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            HeliumDateTime.formatTimeRange(
              HeliumDateTime.toLocal(plannerItem.start, timeZone),
              HeliumDateTime.toLocal(plannerItem.end, timeZone),
              plannerItem.showEndTime,
            ),
            style:
                (isInAgenda
                        ? AppStyles.smallSecondaryTextLight(context)
                        : AppStyles.calendarItemTextLight(context))
                    .copyWith(
                      color: foregroundColor.withValues(
                        alpha: AppStyles.increasedContrastAlpha(0.7),
                      ),
                    ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool _shouldShowRecurringIconWithTime(
    PlannerItemBaseModel plannerItem, {
    bool isInAgenda = false,
  }) {
    return isRecurring(plannerItem) &&
        (isInAgenda ||
            currentView == PlannerView.week ||
            currentView == PlannerView.day);
  }

  Widget _buildRecurringTimePrefixIcon({required Color backgroundColor}) {
    final foregroundColor = backgroundColor.contrasting;
    return Icon(
      Icons.repeat,
      size: _calendarItemIconSize,
      color: foregroundColor.withValues(
        alpha: AppStyles.increasedContrastAlpha(0.4),
      ),
    );
  }

  Widget _buildCalendarItemOnlineRow(
    BuildContext context, {
    required bool isInAgenda,
    required Color backgroundColor,
  }) {
    return _buildCalendarItemIconRow(
      context,
      Icons.language,
      'Online',
      isInAgenda: isInAgenda,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildCalendarItemLocationRow(
    BuildContext context,
    String location, {
    required bool isInAgenda,
    required Color backgroundColor,
  }) {
    return _buildCalendarItemIconRow(
      context,
      Icons.pin_drop_outlined,
      location,
      isInAgenda: isInAgenda,
      backgroundColor: backgroundColor,
    );
  }

  /// Drops the icon in items too narrow to hold it, like crowded Week columns.
  Widget _buildCalendarItemIconRow(
    BuildContext context,
    IconData icon,
    String text, {
    required bool isInAgenda,
    required Color backgroundColor,
  }) {
    final foregroundColor = backgroundColor.contrasting;
    final label = Text(
      text,
      style:
          (isInAgenda
                  ? AppStyles.smallSecondaryTextLight(context)
                  : AppStyles.calendarItemTextLight(context))
              .copyWith(
                color: foregroundColor.withValues(
                  alpha: AppStyles.increasedContrastAlpha(0.7),
                ),
              ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            _calendarItemIconSize + _calendarItemIconGap) {
          return label;
        }
        return Row(
          children: [
            Icon(
              icon,
              size: _calendarItemIconSize,
              color: foregroundColor.withValues(
                alpha: AppStyles.increasedContrastAlpha(0.4),
              ),
            ),
            const SizedBox(width: _calendarItemIconGap),
            Expanded(child: label),
          ],
        );
      },
    );
  }
}

class PlannerMoreIndicator extends StatelessWidget {
  final CalendarAppointmentDetails details;
  final int displayCount;
  final void Function(DateTime? date) onOpenDay;

  const PlannerMoreIndicator({
    super.key,
    required this.details,
    required this.displayCount,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        onOpenDay(details.date);
      },
      child: UnconstrainedBox(
        alignment: Alignment.topLeft,
        constrainedAxis: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        child: Container(
          width: details.bounds.width,
          height: PlannerMonthLayout.monthCalendarItemHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '+${details.appointments.length - (displayCount - 1)} more',
            style: AppStyles.calendarItemTextLight(context).copyWith(
              color: context.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.9,
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
