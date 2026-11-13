import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// A row of weekday chips. Values are Sunday-indexed (0 = Sunday, 6 =
/// Saturday) whatever [weekStartsOn] orders them by.
class WeekdaySelector extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final int weekStartsOn;

  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.weekStartsOn = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: List.generate(7, _segmentAt),
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Responsive.isSlimMobile(context) ? 6 : 8),
        ),
        textStyle: WidgetStateProperty.all(
          AppStyles.buttonText(context).copyWith(
            fontSize: Responsive.getFontSize(
              context,
              slimMobile: 12,
              mobile: 13,
              desktop: 14,
            ),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => _backgroundColor(context, states),
        ),
      ),
      selected: selected,
      onSelectionChanged: onChanged,
      emptySelectionAllowed: false,
      multiSelectionEnabled: true,
      showSelectedIcon: false,
    );
  }

  ButtonSegment<int> _segmentAt(int position) {
    final dayIndex = (weekStartsOn + position) % 7;
    return ButtonSegment<int>(
      value: dayIndex,
      label: Text(CalendarConstants.dayNamesAbbrev[dayIndex]),
    );
  }

  Color _backgroundColor(BuildContext context, Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return context.colorScheme.primary;
    }
    return Colors.transparent;
  }
}
