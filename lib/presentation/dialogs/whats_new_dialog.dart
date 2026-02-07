// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/whats_new_service.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
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
          Text("What's New", style: AppStyles.pageTitle(context)),
        ],
      ),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the new Helium!',
                style: AppStyles.featureText(context),
              ),
              const SizedBox(height: 12),
              Text(
                "We've completely rebuilt Helium from the ground up with a fresh, modern design, improved performance, and room to grow.",
                style: AppStyles.standardBodyText(context),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.palette_outlined,
                title: 'New look',
                description: 'A cleaner, more intuitive interface',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                icon: Icons.devices_outlined,
                title: 'Cross-platform',
                description: 'Now with native mobile apps',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                icon: Icons.trending_up_outlined,
                title: 'Evolving',
                description:
                    'More features coming soon',
              ),
              const SizedBox(height: 12),
              Text(
                "We're still working to ensure all of Helium's existing features are in the new version, but we wanted to give you early access to the new experience while we finish polishing.",
                style: AppStyles.standardBodyText(context),
              ),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: HeliumElevatedButton(
            buttonText: 'Dive In!',
            onPressed: () async {
              await WhatsNewService().markWhatsNewAsSeen();
              if (context.mounted) {
                Navigator.pop(context);
              }
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
              Text(title, style: AppStyles.menuItem(context)),
              Text(description, style: AppStyles.menuItemHint(context)),
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
