// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/whats_new_service.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/support_helium_card.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

const String whatsNewDismissButtonKey = 'whats_new_dismiss_button';

class _WhatsNewDialogWidget extends StatefulWidget {
  const _WhatsNewDialogWidget();

  @override
  State<_WhatsNewDialogWidget> createState() => _WhatsNewDialogWidgetState();
}

class _WhatsNewDialogWidgetState extends State<_WhatsNewDialogWidget> {
  @override
  void initState() {
    super.initState();
    router.routerDelegate.addListener(_dismissIfOverlayActive);
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_dismissIfOverlayActive);
    super.dispose();
  }

  /// Pops this dialog when the user opens a route-based overlay (settings,
  /// notifications, an entity editor). The promotional dialog yields to
  /// any deliberate navigation rather than being left stranded under it.
  void _dismissIfOverlayActive() {
    if (!mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final onShellTab =
        NavigationPage.values.any((page) => page.route == path);
    if (!onShellTab) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AlertDialog(
      insetPadding: isMobile
          ? const EdgeInsets.only(
              left: 40.0,
              right: 40.0,
              top: 15,
              bottom: 15,
            )
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: context.colorScheme.primary,
            size: 28.0,
          ),
          const SizedBox(width: 12),
          SelectableText(
            "What's New?",
            style: AppStyles.pageTitle(context),
          ),
        ],
      ),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              "Your study sidekick just leveled up. Here's what changed.",
              style: AppStyles.standardBodyText(context),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What's New is a fixed-size stack of 4 items. For every new entry
                    // added at the top, remove one from the bottom. Order reflects recency:
                    // newest feature first, oldest last.
                    _buildFeatureItem(
                      context,
                      icon: Icons.trending_up,
                      title: 'Grade Projection',
                      description:
                          '"What Could I Get?" — project your final grade based on how you do on remaining assignments',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.link,
                      title: 'Link & Unlink Notes',
                      description:
                          'Re-link a note to a different item, or turn it standalone, without leaving the editor',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.print_outlined,
                      title: 'Print & Export',
                      description:
                          'Print anything across the app, including your formatted notes, or export "Todos" to CSV',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.school,
                      title: 'Class Reminders',
                      description:
                          "Reminders can be added to a class, so you can now receive push notifications when it's time for class",
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const SupportHeliumCard(compact: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: HeliumElevatedButton(
            key: const Key(whatsNewDismissButtonKey),
            buttonText: 'Dive In!',
            onPressed: () async {
              try {
                await WhatsNewService().markWhatsNewAsSeen();
                if (!context.mounted) return;
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              } catch (_) {}
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: context.colorScheme.primary, size: 20.0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                title,
                style: AppStyles.headingText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              SelectableText(
                description,
                style: AppStyles.smallSecondaryText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showWhatsNewDialog(BuildContext parentContext) {
  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const _WhatsNewDialogWidget();
    },
  );
}
