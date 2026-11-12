import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/donation_config.dart';
import 'package:heliumapp/core/whats_new_service.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/support_helium_card.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

const String whatsNewDismissButtonKey = 'whats_new_dismiss_button';

class _WhatsNewDialogWidget extends StatefulWidget {
  final int versionSeen;

  const _WhatsNewDialogWidget({required this.versionSeen});

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
    if (!onShellTab && Navigator.canPop(context)) {
      router.routerDelegate.removeListener(_dismissIfOverlayActive);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final features = [
      (
        version: 15,
        item: _buildFeatureItem(
          context,
          icon: Icons.repeat,
          title: 'Repeating Assignments & Events',
          description:
              'Assignments and events can now repeat, so a weekly reading or a monthly meeting only needs adding once',
        ),
      ),
      (
        version: 14,
        item: _buildFeatureItem(
          context,
          icon: Icons.calculate,
          title: 'GPA Tracking',
          description:
              'Add credits to your classes and pick your school\'s grade scale, then watch your GPA update with every grade',
        ),
      ),
      (
        version: 13,
        item: _buildFeatureItem(
          context,
          icon: Icons.attach_file,
          title: 'Class Notes & Resource Attachments',
          description:
              'Add a note to any class and attachments to any resource, and see class and resource attachments on each assignment',
        ),
      ),
      (
        version: 11,
        item: _buildFeatureItem(
          context,
          icon: Icons.tune,
          title: 'Your Planner, Your Way',
          description:
              'Try the new 3-day view, pick your date, time, and number formats under Preferences, and search inside your notes',
        ),
      ),
    ];
    final unseenFeatures = [
      for (final feature in features)
        if (feature.version > widget.versionSeen) feature.item,
    ];

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
                    for (final (index, feature) in unseenFeatures.indexed) ...[
                      if (index > 0) const SizedBox(height: 12),
                      feature,
                    ],
                    if (showDonationLink) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const SupportHeliumCard(compact: true),
                    ],
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

Future<void> showWhatsNewDialog(BuildContext parentContext, {required int versionSeen}) {
  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _WhatsNewDialogWidget(versionSeen: versionSeen);
    },
  );
}
