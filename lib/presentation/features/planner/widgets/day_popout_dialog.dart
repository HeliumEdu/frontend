// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class PlannerDayPopOutDialog extends StatefulWidget {
  final DateTime date;
  final PlannerItemDataSource dataSource;
  final bool Function(BuildContext context, PlannerItemBaseModel plannerItem)
  onPlannerItemTap;
  final Widget Function(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
    bool? completedOverride,
  )
  itemBuilder;

  const PlannerDayPopOutDialog({
    required this.date,
    required this.dataSource,
    required this.onPlannerItemTap,
    required this.itemBuilder,
    super.key,
  });

  @override
  State<PlannerDayPopOutDialog> createState() => _PlannerDayPopOutDialogState();
}

class _PlannerDayPopOutDialogState extends State<PlannerDayPopOutDialog> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dataSource.changeNotifier,
      builder: (context, _) {
        final currentItems = widget.dataSource.getItemsForDay(widget.date);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 360,
            constraints: const BoxConstraints(maxHeight: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          HeliumDateTime.formatDateWithDay(widget.date),
                          style: AppStyles.headingText(
                            context,
                          ).copyWith(color: context.colorScheme.onSurface),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: context.colorScheme.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: currentItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final plannerItem = currentItems[index];
                      final completedOverride = widget
                          .dataSource
                          .completedOverrides[plannerItem.id];

                      return GestureDetector(
                        onTap: () {
                          Feedback.forTap(context);
                          if (widget.onPlannerItemTap(context, plannerItem)) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: widget.itemBuilder(
                          context,
                          plannerItem,
                          completedOverride,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
