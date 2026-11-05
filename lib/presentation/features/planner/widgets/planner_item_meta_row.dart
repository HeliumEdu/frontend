import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/ui/components/hover_tap_target.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
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

  final int pulledThroughAttachmentCount;

  final void Function(BuildContext anchorContext)? onOpenAttachments;

  final List<ResourceModel> resources;

  final void Function(BuildContext anchorContext)? onOpenResources;

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
    this.pulledThroughAttachmentCount = 0,
    this.onOpenAttachments,
    this.resources = const [],
    this.onOpenResources,
    this.maxEntries = 3,
  });

  static bool hasAny(
    PlannerItemBaseModel plannerItem, {
    int pulledThroughAttachmentCount = 0,
    int resourceCount = 0,
  }) {
    if (_linkedNoteId(plannerItem) != null) return true;
    if (plannerItem is HomeworkModel && resourceCount > 0) return true;
    if (plannerItem.attachments.isNotEmpty) return true;
    if (pulledThroughAttachmentCount > 0) return true;
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
          onTap: onOpenInNotebook == null ? null : (_) => onOpenInNotebook!(),
          tooltip: onOpenInNotebook != null ? 'Open in Notebook' : null,
        ),
      );
    }

    final attachmentCount =
        item.attachments.length + pulledThroughAttachmentCount;
    if (attachmentCount > 0) {
      entries.add(
        _MetaEntry.count(
          icon: Icons.attachment,
          count: attachmentCount,
          color: context.semanticColors.success.withValues(alpha: 0.9),
          onTap: onOpenAttachments,
          tooltip: onOpenAttachments != null ? 'Show attachments' : null,
        ),
      );
    }

    if (item is HomeworkModel && resources.isNotEmpty) {
      entries.add(
        _MetaEntry.count(
          icon: Icons.book_outlined,
          count: resources.length,
          color: userSettings.resourceColor.withValues(alpha: 0.9),
          onTap: onOpenResources,
          tooltip: onOpenResources != null ? 'Show resources' : null,
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
    double startPadding(int i) =>
        i > 0 && visible[i].onTap != null ? groupGap / 2 : 0;
    double endPadding(int i) =>
        i < visible.length - 1 && visible[i].onTap != null ? groupGap / 2 : 0;
    final verticalPadding = math.max(
      0.0,
      (HoverTapTarget.extentOf(context) - iconSize) / 2,
    );

    final children = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0) {
        children.add(
          SizedBox(width: groupGap - endPadding(i - 1) - startPadding(i)),
        );
      }
      children.add(
        _buildEntry(
          visible[i],
          hitPadding: EdgeInsets.fromLTRB(
            startPadding(i),
            verticalPadding,
            endPadding(i),
            verticalPadding,
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildEntry(_MetaEntry entry, {required EdgeInsets hitPadding}) {
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

    final onTap = entry.onTap;
    if (onTap == null) return visual;

    return HoverTapTarget(
      onTap: onTap,
      color: entry.color,
      tooltip: entry.tooltip,
      hitPadding: hitPadding,
      child: visual,
    );
  }
}

class _MetaEntry {
  final IconData icon;
  final int? count;
  final Color color;
  final void Function(BuildContext anchorContext)? onTap;
  final String? tooltip;

  _MetaEntry.count({
    required this.icon,
    required int this.count,
    required this.color,
    this.onTap,
    this.tooltip,
  });

  _MetaEntry.iconOnly({
    required this.icon,
    required this.color,
    this.onTap,
    this.tooltip,
  }) : count = null;
}
