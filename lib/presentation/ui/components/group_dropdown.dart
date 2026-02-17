// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class GroupDropdown<T extends BaseTitledModel> extends StatelessWidget {
  final List<T> groups;
  final ValueChanged<T?> onChanged;
  final bool isReadOnly;
  final VoidCallback? onCreate;
  final Function(T)? onEdit;
  final Function(T)? onDelete;
  final T? initialSelection;

  const GroupDropdown({
    super.key,
    required this.groups,
    required this.onChanged,
    this.isReadOnly = false,
    this.onCreate,
    this.onEdit,
    this.onDelete,
    this.initialSelection,
  });

  @override
  Widget build(BuildContext context) {
    // When empty and not read-only, show the "+ Group" button directly
    if (groups.isEmpty && !isReadOnly) {
      return ShadowContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        borderColor: context.colorScheme.outline.withValues(alpha: 0.2),
        child: HeliumElevatedButton(
          onPressed: onCreate!,
          buttonText: 'Group',
          icon: Icons.add,
        ),
      );
    }

    final items = groups.map((item) {
      return DropdownMenuItem(value: item, child: _buildItem(context, item));
    }).toList();
    if (!isReadOnly) {
      items.add(
        DropdownMenuItem<T>(
          value: null,
          enabled: false,
          child: HeliumElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onCreate!();
            },
            buttonText: 'Group',
            icon: Icons.add,
          ),
        ),
      );
    }

    return ShadowContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      borderColor: context.colorScheme.outline.withValues(alpha: 0.2),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<T>(
            icon: Icon(Icons.keyboard_arrow_down, color: context.colorScheme.primary),
            dropdownColor: context.colorScheme.surface,
            isExpanded: true,
            underline: const SizedBox(),
            value: initialSelection,
            items: items,
            selectedItemBuilder: (BuildContext context) {
              return groups.map<Widget>((T item) {
                return _buildItem(context, item);
              }).toList();
            },
            onChanged: onChanged,
            alignment: AlignmentDirectional.centerStart,
            menuMaxHeight: 400,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, T item) {
    String? dateRange;
    if (item is CourseGroupModel) {
      dateRange =
          '${HeliumDateTime.formatDate(item.startDate)} to ${HeliumDateTime.formatDate(item.endDate)}';
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: AppStyles.formText(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!item.shownOnCalendar!) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.visibility_off,
                            size: 18,
                            color: context.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (dateRange != null)
                      Text(
                        dateRange,
                        style: AppStyles.smallSecondaryTextLight(context)
                            .copyWith(
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...buildEditButtons(context, item),
      ],
    );
  }

  List<Widget> buildEditButtons(BuildContext context, T item) {
    return isReadOnly
        ? []
        : [
            const SizedBox(width: 12),
            HeliumIconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                onEdit!(item);
              },
              icon: Icons.edit_outlined,
            ),
            const SizedBox(width: 8),
            HeliumIconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                showConfirmDeleteDialog(
                  parentContext: context,
                  item: item,
                  additionalWarning:
                      'Anything in this group will also be deleted.',
                  onDelete: (value) {
                    onDelete!(value);
                  },
                );
              },
              icon: Icons.delete_outlined,
              color: context.colorScheme.error,
            ),
          ];
  }
}
