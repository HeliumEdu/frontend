import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class PillBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const PillBadge({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.semanticColors.success;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveValue(context, mobile: 6, desktop: 8),
        vertical: Responsive.getResponsiveValue(context, mobile: 3, desktop: 4),
      ),
      decoration: BoxDecoration(
        color: BadgeColors.background(context, effectiveColor),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: BadgeColors.border(context, effectiveColor),
        ),
      ),
      child: Text(
        text,
        style: AppStyles.smallSecondaryText(context).copyWith(
          color: BadgeColors.foreground(context, effectiveColor),
        ),
      ),
    );
  }
}
