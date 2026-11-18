import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/planner_month_layout.dart';

void main() {
  group('PlannerMonthLayout', () {
    group('calculateCalendarItemDisplayCount', () {
      test('unbounded height uses minimum count', () {
        // GIVEN
        const availableHeight = double.infinity;

        // WHEN
        final count = PlannerMonthLayout.calculateCalendarItemDisplayCount(
          availableHeight,
        );

        // THEN
        expect(count, PlannerMonthLayout.monthMinItemDisplayCount);
      });

      test('fits whole item slots per cell', () {
        // GIVEN
        const availableHeight = 1200.0;

        // WHEN
        final count = PlannerMonthLayout.calculateCalendarItemDisplayCount(
          availableHeight,
        );

        // THEN
        expect(
          count,
          7,
          reason: '(1200 - 45) / 6 - 30 = 162.5 px per cell, 23 px per slot',
        );
      });

      test('short height clamps to minimum count', () {
        // GIVEN
        const availableHeight = 100.0;

        // WHEN
        final count = PlannerMonthLayout.calculateCalendarItemDisplayCount(
          availableHeight,
        );

        // THEN
        expect(count, PlannerMonthLayout.monthMinItemDisplayCount);
      });

      test('tall height clamps to ten', () {
        // GIVEN
        const availableHeight = 5000.0;

        // WHEN
        final count = PlannerMonthLayout.calculateCalendarItemDisplayCount(
          availableHeight,
        );

        // THEN
        expect(count, 10);
      });
    });

    group('calculateCalendarHeight', () {
      test('unbounded height uses mobile minimum', () {
        // GIVEN
        const maxHeight = double.infinity;

        // WHEN
        final height = PlannerMonthLayout.calculateCalendarHeight(
          maxHeight,
          isMobile: true,
        );

        // THEN
        expect(height, PlannerMonthLayout.minCalendarHeightMobile);
      });

      test('short height grows to desktop minimum', () {
        // GIVEN
        const maxHeight = 300.0;

        // WHEN
        final height = PlannerMonthLayout.calculateCalendarHeight(
          maxHeight,
          isMobile: false,
        );

        // THEN
        expect(height, PlannerMonthLayout.minCalendarHeightDesktop);
      });

      test('tall height fills available space', () {
        // GIVEN
        const maxHeight = 900.0;

        // WHEN
        final height = PlannerMonthLayout.calculateCalendarHeight(
          maxHeight,
          isMobile: false,
        );

        // THEN
        expect(height, 900.0);
      });
    });

    group('calculateMaxItemsForVisibleDates', () {
      test('no data source is zero', () {
        // GIVEN
        final visibleDates = [DateTime(2026, 11, 1)];

        // WHEN
        final maxItems = PlannerMonthLayout.calculateMaxItemsForVisibleDates(
          null,
          visibleDates,
        );

        // THEN
        expect(maxItems, 0);
      });
    });

    group('calculateExpandedCalendarHeight', () {
      test('height fits items with gaps and cell padding', () {
        // GIVEN
        const maxItems = 3;

        // WHEN
        final height = PlannerMonthLayout.calculateExpandedCalendarHeight(
          maxItems,
        );

        // THEN
        expect(
          height,
          675.0,
          reason: '45 + 6 * (30 + (3 * 23 - 2) + 8)',
        );
      });

      test('more items grow each row by one slot', () {
        // GIVEN
        const fewer = 3;
        const more = 4;

        // WHEN
        final fewerHeight = PlannerMonthLayout.calculateExpandedCalendarHeight(
          fewer,
        );
        final moreHeight = PlannerMonthLayout.calculateExpandedCalendarHeight(
          more,
        );

        // THEN
        expect(
          moreHeight - fewerHeight,
          6 *
              (PlannerMonthLayout.monthCalendarItemHeight +
                  PlannerMonthLayout.monthCalendarItemGap),
        );
      });
    });
  });
}
