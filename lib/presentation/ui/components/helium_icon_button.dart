import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class HeliumIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final IconData icon;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? minimumSize;
  final VisualDensity? visualDensity;

  const HeliumIconButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    required this.icon,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.minimumSize,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context) {
    final useSize =
        size ??
        Responsive.getIconSize(context, mobile: 20, tablet: 22, desktop: 24);

    // Solid-fill variant: callers pass `backgroundColor` to mirror
    // HeliumElevatedButton's filled style (solid bg + onPrimary icon). When
    // omitted, fall back to the tinted-bubble chrome style (icon color at
    // alpha 0.2 for bg, full color for icon) used by add/edit/delete actions.
    final isSolid = backgroundColor != null;
    final tintColor = color ?? context.colorScheme.primary;
    final effectiveBg = isSolid ? backgroundColor! : tintColor.withValues(alpha: 0.2);
    final hoverBg = isSolid
        ? backgroundColor!.withValues(alpha: 0.85)
        : tintColor.withValues(alpha: 0.4);
    final baseIconColor =
        iconColor ?? (isSolid ? context.colorScheme.onPrimary : tintColor);
    final effectiveIconColor = enabled
        ? baseIconColor
        : baseIconColor.withValues(alpha: 0.4);

    return IconButton.filled(
      style: ButtonStyle(
        backgroundColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return effectiveBg.withValues(alpha: effectiveBg.a * 0.4);
          }
          if (states.contains(WidgetState.hovered)) {
            return hoverBg;
          }
          return effectiveBg;
        }),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, color: effectiveIconColor, size: useSize),
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: minimumSize != null
          ? BoxConstraints(minWidth: minimumSize!, minHeight: minimumSize!)
          : const BoxConstraints(),
      visualDensity: visualDensity,
    );
  }
}
