import 'package:heliumapp/data/sources/planner_item_data_source.dart';

class PlannerMonthLayout {
  PlannerMonthLayout._();

  static const monthCalendarItemHeight = 21.0;
  // SfCalendar adds ~2px between adjacent appointments in month view cells.
  // Both the display-count and expanded-height calculations must account for
  // this gap so the allocated slot height matches monthCalendarItemHeight.
  static const monthCalendarItemGap = 2.0;
  // SfCalendar reserves bottom padding inside each month cell (below the last
  // appointment). Include this in height calculations to prevent clipping.
  static const monthCellBottomPadding = 8.0;
  static const monthMinItemDisplayCount = 3;
  static const minCalendarHeightMobile = 480.0;
  static const minCalendarHeightDesktop = 675.0;

  static int calculateCalendarItemDisplayCount(double availableHeight) {
    const double dayHeaderHeight = 45;
    const double dayNumberHeight = 30;
    const int monthRows = 6;

    if (availableHeight.isInfinite) return monthMinItemDisplayCount;

    final cellHeight = (availableHeight - dayHeaderHeight) / monthRows;
    final availableForCalendarItems = cellHeight - dayNumberHeight;
    // Each item occupies its height plus the inter-item gap SfCalendar inserts.
    final count =
        (availableForCalendarItems /
                (monthCalendarItemHeight + monthCalendarItemGap))
            .floor();

    return count.clamp(monthMinItemDisplayCount, 10);
  }

  static double calculateCalendarHeight(
    double maxHeight, {
    required bool isMobile,
  }) {
    final double minCalendarHeight = isMobile
        ? minCalendarHeightMobile
        : minCalendarHeightDesktop;
    if (maxHeight.isInfinite) return minCalendarHeight;
    return maxHeight < minCalendarHeight ? minCalendarHeight : maxHeight;
  }

  static int calculateMaxItemsForVisibleDates(
    PlannerItemDataSource? plannerItemDataSource,
    List<DateTime> visibleDates,
  ) {
    if (plannerItemDataSource == null || visibleDates.isEmpty) return 0;
    return visibleDates
        .map((date) => plannerItemDataSource.getItemsForDay(date).length)
        .fold(0, (a, b) => a > b ? a : b);
  }

  static double calculateExpandedCalendarHeight(int maxItems) {
    const double dayHeaderHeight = 45;
    const double dayNumberHeight = 30;
    const int monthRows = 6;
    // n items require n slots of (height + gap), minus the trailing gap,
    // plus cell bottom padding SfCalendar reserves below the last item.
    final itemsHeight =
        maxItems * (monthCalendarItemHeight + monthCalendarItemGap) -
        monthCalendarItemGap;
    final cellHeight = dayNumberHeight + itemsHeight + monthCellBottomPadding;
    return dayHeaderHeight + (monthRows * cellHeight);
  }
}
