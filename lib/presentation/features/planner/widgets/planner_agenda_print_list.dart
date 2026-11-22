import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:intl/intl.dart';

/// The agenda as printed: every day from [firstDay] through [lastDay] that
/// has items, each kept whole across page breaks. The on-screen
/// agenda only renders what's scrolled into view, so printing draws the
/// range itself.
class PlannerAgendaPrintList extends StatelessWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime today;
  final double itemHeight;
  final List<PlannerItemBaseModel> Function(DateTime day) itemsForDay;
  final Widget Function(PlannerItemBaseModel item, DateTime day, double width)
  itemBuilder;

  const PlannerAgendaPrintList({
    super.key,
    required this.firstDay,
    required this.lastDay,
    required this.today,
    required this.itemHeight,
    required this.itemsForDay,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final day in PlannerHelper.agendaDaysOf(
          firstDay,
          lastDay,
          itemsForDay,
        ))
          PrintPageBreak(child: _buildDay(context, day.date, day.items)),
      ],
    );
  }

  Widget _buildDay(
    BuildContext context,
    DateTime date,
    List<PlannerItemBaseModel> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            height: itemHeight,
            child: _buildDayLabel(context, date),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        height: itemHeight,
                        child: itemBuilder(item, date, constraints.maxWidth),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(BuildContext context, DateTime date) {
    final isToday = DateUtils.isSameDay(date, today);
    final dayStyle = AppStyles.smallSecondaryText(
      context,
    ).copyWith(color: context.colorScheme.onSurface);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '${date.day}',
            style: isToday
                ? dayStyle.copyWith(
                    color: AppTheme.onPrimaryText(context.colorScheme),
                  )
                : dayStyle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('MMM, EEE').format(date).toUpperCase(),
          style: isToday
              ? dayStyle.copyWith(
                  color: AppTheme.primaryText(context.colorScheme),
                )
              : dayStyle,
        ),
      ],
    );
  }
}
