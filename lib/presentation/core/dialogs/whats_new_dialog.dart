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
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class _WhatsNewDialogWidget extends StatelessWidget {
  const _WhatsNewDialogWidget();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: context.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Welcome to the new Helium!',
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
              "We've completely rebuilt Helium from the ground up—sleek, modern, fast, and built to last.",
              style: AppStyles.standardBodyText(context),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(
                      context,
                      icon: Icons.bolt_outlined,
                      title: 'Lightning fast',
                      description:
                          'Snappier performance and a stable foundation',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.phone_iphone_outlined,
                      title: 'Native mobile apps',
                      description:
                          'iOS and Android apps with push notifications',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.sync_outlined,
                      title: 'Seamless sync',
                      description:
                          'Consistent experience across web and mobile',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.construction_outlined,
                      title: 'Still polishing',
                      description:
                          'A few familiar features and settings are still on the way—classic Helium will remain available through at least the Summer',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.rocket_launch_outlined,
                      title: 'New surprises ahead',
                      description: 'Exciting new features on the horizon',
                    ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colorScheme.primary, size: 20),
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

Future<void> showWhatsNewDialog({required BuildContext context}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const _WhatsNewDialogWidget();
    },
  );
}
