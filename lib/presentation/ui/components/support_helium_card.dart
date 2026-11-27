import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class SupportHeliumCard extends StatelessWidget {
  static const _cardBorderRadius = 16.0;
  static const _cardPadding = 16.0;
  static const _iconSize = 32.0;
  static const _iconGap = 12.0;
  static const _arrowIconSize = 16.0;

  const SupportHeliumCard({
    super.key,
    this.compact = false,
    this.showRating = false,
  });

  final bool compact;

  final bool showRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary.withValues(alpha: 0.08),
            context.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildAction(
              context,
              icon: Icons.volunteer_activism,
              title: AppLocalizations.of(context).supportHeliumKeepFreeTitle,
              hint: compact
                  ? AppLocalizations.of(context).supportHeliumKeepFreeCompactHint
                  : AppLocalizations.of(context).supportHeliumKeepFreeHint,
              onTap: () => UrlHelpers.launchWebUrl(AppConstants.patreonUrl),
            ),
            if (showRating) ...[
              Divider(
                height: 1,
                indent: _cardPadding + _iconSize + _iconGap,
                color: context.colorScheme.primary.withValues(alpha: 0.2),
              ),
              _buildAction(
                context,
                icon: Icons.star,
                title: AppLocalizations.of(context).supportHeliumRateTitle,
                hint: AppLocalizations.of(context).supportHeliumRateHint,
                onTap: UrlHelpers.launchStoreListing,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Row(
          children: [
            Icon(icon, color: context.colorScheme.primary, size: _iconSize),
            const SizedBox(width: _iconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.menuItem(
                      context,
                    ).copyWith(color: context.colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(hint, style: AppStyles.menuItemHint(context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: context.colorScheme.onSurface.withValues(alpha: 0.3),
              size: _arrowIconSize,
            ),
          ],
        ),
      ),
    );
  }
}
