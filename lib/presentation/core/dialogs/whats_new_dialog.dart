// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/whats_new_service.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/support_helium_card.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class _WhatsNewDialogWidget extends StatelessWidget {
  const _WhatsNewDialogWidget();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: context.colorScheme.primary,
            size: 28.0,
          ),
          const SizedBox(width: 12),
          Text(
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
                    // What's New rotation: new features are added at the top, pushing each
                    // existing item down one position. When the list exceeds 4-5 items, drop
                    // the bottom-most feature (above 'New surprises ahead').
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
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.calendar_month,
                      title: 'Cancellations & Holidays',
                      description:
                          'Exclude specific sessions from a recurring class schedule, or set holidays for a term that apply across all classes',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.library_books,
                      title: 'Notebook',
                      description:
                          'Rich notes help you link all your work together',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.rocket_launch_outlined,
                      title: 'New surprises ahead',
                      description: 'Exciting new features on the horizon',
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'https://heliumedu.freshdesk.com/support/solutions/articles/159000427014',
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Learn more',
                            style: AppStyles.buttonText(context).copyWith(
                              color: context.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: Responsive.getIconSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            color: context.colorScheme.primary,
                          ),
                        ],
                      ),
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
            buttonText: 'Dive In!',
            onPressed: () async {
              await WhatsNewService().markWhatsNewAsSeen();
              if (!context.mounted) return;
              Navigator.pop(context);
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
