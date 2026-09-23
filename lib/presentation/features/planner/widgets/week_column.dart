import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Week number column for the planner month view, rendered beside SfCalendar
/// rather than by it, which sizes its own column from the calendar width
/// instead of the text it holds and so grows without bound.
class WeekColumn extends StatelessWidget {
  final List<DateTime> visibleDates;

  final double headerHeight;
  final String label;
  final TextStyle textStyle;

  const WeekColumn({
    super.key,
    required this.visibleDates,
    required this.headerHeight,
    required this.label,
    required this.textStyle,
  });

  /// Lines the number up with the day number beside it.
  static const double _topPadding = 9;

  static const double _numberPadding = 6;

  static const double _labelPadding = 2;

  static const String _widestWeekNumber = '53';

  /// SfCalendar draws its row separators across the full grid width, so they
  /// carry on through this column.
  static const double _separatorAlpha = 0.16;

  static const double _separatorWidth = 0.5;

  static const double _backgroundAlpha = 0.04;

  static double widthFor(
    BuildContext context, {
    required String label,
    required TextStyle textStyle,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    if (Responsive.isDesktop(context)) {
      return _measure(label, textStyle, textScaler) + (_labelPadding * 2);
    }
    return _measure(_widestWeekNumber, textStyle, textScaler) +
        (_numberPadding * 2);
  }

  static double _measure(String text, TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    return painter.width;
  }

  int get _rowCount => visibleDates.length ~/ DateTime.daysPerWeek;

  /// ISO weeks run Monday to Sunday, so a row belongs to the week holding its
  /// Monday rather than its first date, which moves with `weekStartsOn`.
  String _weekNumberForRow(int row) {
    final start = row * DateTime.daysPerWeek;
    final end = start + DateTime.daysPerWeek;
    for (var i = start; i < end && i < visibleDates.length; i++) {
      if (visibleDates[i].weekday == DateTime.monday) {
        return HeliumDateTime.isoWeekNumber(visibleDates[i]).toString();
      }
    }
    return '';
  }

  /// Falls back to the label's initial, then to nothing, as the column narrows.
  Widget _buildLabel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        for (final candidate in [label, label.substring(0, 1)]) {
          if (_measure(candidate, textStyle, textScaler) <=
              constraints.maxWidth) {
            return Center(
              child: Text(candidate, style: textStyle, maxLines: 1),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRow(BuildContext context, int row) {
    final isLastRow = row == _rowCount - 1;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: isLastRow
              ? null
              : Border(
                  bottom: BorderSide(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: _separatorAlpha,
                    ),
                    width: _separatorWidth,
                  ),
                ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: _topPadding),
            child: Text(_weekNumberForRow(row), style: textStyle, maxLines: 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: headerHeight, child: _buildLabel(context)),
        Expanded(
          child: ColoredBox(
            color: context.colorScheme.onSurface.withValues(
              alpha: _backgroundAlpha,
            ),
            child: Column(
              children: List.generate(
                _rowCount,
                (row) => _buildRow(context, row),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
