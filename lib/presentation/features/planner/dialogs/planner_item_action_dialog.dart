import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// One row of the action menu
class PlannerItemAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const PlannerItemAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
}

/// Shows an adaptive action menu for a planner item that can't be edited in
/// place, headed by the owning entity's name and the occurrence date. The
/// entity-specific menus (course schedule, external calendar) build on this.
///
/// On mobile this uses a bottom sheet. On desktop a centered dialog is used
/// because SfCalendar's onTap callback provides no pixel position for the
/// tapped tile, making a reliably-anchored popup menu impossible.
void showPlannerItemActionDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Color color,
  required DateTime occurrenceDate,
  required List<PlannerItemAction> actions,
}) {
  final isMobile = Responsive.isMobile(context);

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (menuContext, setMenuState) => _buildContent(
          menuContext,
          isMobile: isMobile,
          icon: icon,
          title: title,
          color: color,
          occurrenceDate: occurrenceDate,
          actions: actions,
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (menuContext, setMenuState) => _buildContent(
              menuContext,
              isMobile: isMobile,
              icon: icon,
              title: title,
              color: color,
              occurrenceDate: occurrenceDate,
              actions: actions,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildContent(
  BuildContext menuContext, {
  required bool isMobile,
  required IconData icon,
  required String title,
  required Color color,
  required DateTime occurrenceDate,
  required List<PlannerItemAction> actions,
}) {
  return Material(
    color: menuContext.colorScheme.surface,
    borderRadius: isMobile
        ? const BorderRadius.vertical(top: Radius.circular(16))
        : BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.formText(menuContext).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isMobile)
                      IconButton(
                        onPressed: () => Navigator.of(menuContext).pop(),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: menuContext.colorScheme.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: menuContext.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      HeliumDateTime.formatDate(occurrenceDate),
                      style: AppStyles.formText(menuContext).copyWith(
                        color: menuContext.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          for (final action in actions)
            _buildMenuItem(
              context: menuContext,
              icon: action.icon,
              label: action.label,
              iconColor: action.iconColor,
              onTap: () {
                Navigator.pop(menuContext);
                action.onTap();
              },
            ),
          if (isMobile) const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _buildMenuItem({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color? iconColor,
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: iconColor ?? context.colorScheme.primary,
      size: 20,
    ),
    title: Text(label, style: AppStyles.formText(context)),
    onTap: onTap,
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
