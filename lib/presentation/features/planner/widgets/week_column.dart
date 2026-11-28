import 'package:flutter/foundation.dart';
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

  static const double _sfCalendarTimeRulerWidth = 50;

  /// The part of [label] that fits where SfCalendar draws its own week number
  /// label (its time ruler, or its month view column beside a calendar
  /// [calendarWidth] wide), measured as SfCalendar paints it, with the same
  /// fallback as this column's own label. Off Android and iOS, SfCalendar's
  /// month view column is too narrow for any label and already falls back to
  /// its first letters, so [label] passes through there.
  static String sfCalendarLabelFor(
    BuildContext context, {
    required String label,
    required TextStyle textStyle,
    required bool isMonthView,
    required double calendarWidth,
  }) {
    final platform = Theme.of(context).platform;
    final isMobilePlatform =
        !kIsWeb &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
    if (isMonthView && !isMobilePlatform) return label;
    return _fittedLabel(
      label,
      Theme.of(context).textTheme.bodyMedium!.merge(textStyle),
      TextScaler.linear(MediaQuery.textScalerOf(context).scale(1)),
      isMonthView
          ? calendarWidth / (DateTime.daysPerWeek + 1) / 1.3
          : _sfCalendarTimeRulerWidth,
    );
  }

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

  static String _fittedLabel(
    String label,
    TextStyle style,
    TextScaler textScaler,
    double maxWidth,
  ) {
    for (final candidate in [label, label.substring(0, 1)]) {
      if (_measure(candidate, style, textScaler) <= maxWidth) {
        return candidate;
      }
    }
    return '';
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
      builder: (context, constraints) => Center(
        child: Text(
          _fittedLabel(
            label,
            textStyle,
            MediaQuery.textScalerOf(context),
            constraints.maxWidth,
          ),
          style: textStyle,
          maxLines: 1,
        ),
      ),
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
