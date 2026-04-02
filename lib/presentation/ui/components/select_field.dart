// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class SelectField<T extends BaseTitledModel> extends StatelessWidget {
  final List<T> items;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final Widget Function(T item, VoidCallback onDelete) labelBuilder;
  final String buttonLabel;
  final bool enabled;

  const SelectField({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    required this.labelBuilder,
    required this.buttonLabel,
    this.enabled = true,
  });

  void _openSelectMenu(BuildContext buttonContext) {
    final isMobile = Responsive.isMobile(buttonContext);
    final parentContext = buttonContext;
    final selected = Set<int>.of(selectedIds);

    Widget buildContent(BuildContext menuContext, StateSetter setMenuState) {
      return Material(
        color: Theme.of(parentContext).colorScheme.surface,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                final checked = selected.contains(item.id);

                Color? itemColor;
                if (item is CourseModel) {
                  itemColor = item.color;
                }

                return CheckboxListTile(
                  title: Row(
                    children: [
                      if (itemColor != null) ...[
                        Container(
                          width: 12.0,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppStyles.formText(parentContext),
                        ),
                      ),
                    ],
                  ),
                  value: checked,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    if (value == true) {
                      selected.add(item.id);
                    } else {
                      selected.remove(item.id);
                    }
                    setMenuState(() {});
                    onChanged(selected.toList());
                  },
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: parentContext,
        isScrollControlled: true,
        backgroundColor: Theme.of(parentContext).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (context) => StatefulBuilder(builder: buildContent),
      );
    } else {
      final RenderBox button = buttonContext.findRenderObject() as RenderBox;
      final RenderBox overlay =
          Overlay.of(parentContext).context.findRenderObject() as RenderBox;
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );

      showMenu(
        context: parentContext,
        position: position,
        color: Theme.of(parentContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        items: [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(builder: buildContent),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = selectedIds
        .map((id) => items.cast<T?>().firstWhere(
              (item) => item!.id == id,
              orElse: () => null,
            ))
        .whereType<T>()
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
        color: context.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedItems.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: selectedItems.map((item) {
                return labelBuilder(
                  item,
                  () {
                    final updated = List<int>.of(selectedIds)..remove(item.id);
                    onChanged(updated);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: AbsorbPointer(
              absorbing: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Builder(
                  builder: (buttonContext) => TextButton.icon(
                    onPressed: () => _openSelectMenu(buttonContext),
                    icon: Icon(Icons.add, color: context.colorScheme.primary),
                    label: Text(
                      buttonLabel,
                      style: AppStyles.formLabel(
                        context,
                      ).copyWith(color: context.colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
