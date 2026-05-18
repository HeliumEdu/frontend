// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';

/// Row of meta indicators (linked note, resources, attachments, reminders) for
/// a [PlannerItemBaseModel]; shared by the planner tooltip and todos grid.
class PlannerItemMetaRow extends StatelessWidget {
  final PlannerItemBaseModel plannerItem;
  final UserSettingsModel userSettings;
  final TextStyle countTextStyle;
  final double iconSize;
  final double groupGap;
  final VoidCallback? onOpenInNotebook;

  /// Cap on rendered entries; null renders all. Defaults to 3 for the todos
  /// grid's fixed-width cell; the planner tooltip passes null.
  final int? maxEntries;

  const PlannerItemMetaRow({
    super.key,
    required this.plannerItem,
    required this.userSettings,
    required this.countTextStyle,
    this.iconSize = 14,
    this.groupGap = 12,
    this.onOpenInNotebook,
    this.maxEntries = 3,
  });

  static bool hasAny(PlannerItemBaseModel plannerItem) {
    if (_linkedNoteId(plannerItem) != null) return true;
    if (plannerItem is HomeworkModel && plannerItem.resources.isNotEmpty) {
      return true;
    }
    if (plannerItem.attachments.isNotEmpty) return true;
    if (plannerItem.reminders.isNotEmpty) return true;
    return false;
  }

  static int? _linkedNoteId(PlannerItemBaseModel plannerItem) {
    if (plannerItem is HomeworkModel && plannerItem.notes.isNotEmpty) {
      return plannerItem.notes.first.id;
    }
    if (plannerItem is EventModel && plannerItem.notes.isNotEmpty) {
      return plannerItem.notes.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = plannerItem;
    final entries = <_MetaEntry>[];

    if (_linkedNoteId(item) != null) {
      entries.add(
        _MetaEntry.iconOnly(
          icon: Icons.library_books,
          color: context.colorScheme.primary,
          onTap: onOpenInNotebook,
          tooltip: onOpenInNotebook != null ? 'Open in Notebook' : null,
        ),
      );
    }

    if (item.attachments.isNotEmpty) {
      entries.add(
        _MetaEntry.count(
          icon: Icons.attachment,
          count: item.attachments.length,
          color: context.semanticColors.success.withValues(alpha: 0.9),
        ),
      );
    }

    if (item is HomeworkModel && item.resources.isNotEmpty) {
      entries.add(
        _MetaEntry.count(
          icon: Icons.book_outlined,
          count: item.resources.length,
          color: userSettings.resourceColor.withValues(alpha: 0.9),
        ),
      );
    }

    if (item.reminders.isNotEmpty) {
      entries.add(
        _MetaEntry.count(
          icon: Icons.notifications_outlined,
          count: item.reminders.length,
          color: context.colorScheme.primary.withValues(alpha: 0.9),
        ),
      );
    }

    final visible = maxEntries == null
        ? entries
        : entries.take(maxEntries!).toList();
    final children = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0) children.add(SizedBox(width: groupGap));
      children.add(_buildEntry(visible[i]));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildEntry(_MetaEntry entry) {
    final iconWidget = Icon(entry.icon, size: iconSize, color: entry.color);
    final visual = entry.count == null
        ? iconWidget
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 4),
              Text(
                '${entry.count}',
                style: countTextStyle.copyWith(color: entry.color),
              ),
            ],
          );

    if (entry.onTap == null) return visual;

    Widget wrapped = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: entry.onTap,
        child: visual,
      ),
    );
    if (entry.tooltip != null) {
      wrapped = Tooltip(message: entry.tooltip!, child: wrapped);
    }
    return wrapped;
  }
}

class _MetaEntry {
  final IconData icon;
  final int? count;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  _MetaEntry.count({
    required this.icon,
    required int this.count,
    required this.color,
  }) : onTap = null,
       tooltip = null;

  _MetaEntry.iconOnly({
    required this.icon,
    required this.color,
    this.onTap,
    this.tooltip,
  }) : count = null;
}
