// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/responsive_center_card.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:url_launcher/url_launcher.dart';

class MobileWebPromptScreen extends StatefulWidget {
  final String nextRoute;

  const MobileWebPromptScreen({super.key, required this.nextRoute});

  @override
  State<MobileWebPromptScreen> createState() => _MobileWebPromptScreenState();
}

class _MobileWebPromptScreenState
    extends BasePageScreenState<MobileWebPromptScreen> {
  @override
  String get screenTitle => 'Get the Helium App';

  @override
  bool get isAuthenticatedScreen => false;

  bool _isOpeningStore = false;

  @override
  Widget buildScaffold(BuildContext context) {
    return Title(
      title: screenTitle,
      color: context.colorScheme.primary,
      child: Scaffold(body: SafeArea(child: buildMainArea(context))),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return ResponsiveCenterCard(
      maxWidth: 350,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_iphone_outlined,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.colorScheme.primary.withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_rounded, color: context.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Get the Helium App',
            style: AppStyles.pageTitle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The native app is faster, smoother, and designed for your phone.',
            style: AppStyles.standardBodyText(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Push notifications',
            description: 'Stay on top of everything with reminders.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            context,
            icon: Icons.touch_app_outlined,
            title: 'Better mobile UX',
            description: 'Designed for touch, gestures, and small screens.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            context,
            icon: Icons.sync_outlined,
            title: 'Everything stays synced',
            description: 'Seamlessly transition between web, iOS, and Android.',
          ),
          const SizedBox(height: 18),
          ..._buildStoreButtonsForDetectedPlatform(),
          if (_isOpeningStore) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: _continueOnWeb,
            child: const Text('Continue on web'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStoreButtonsForDetectedPlatform() {
    final isIOS = Responsive.isIOSPlatform();
    final isAndroid = Responsive.isAndroidPlatform();

    final iosButton = _buildStoreButton(
      button: Buttons.apple,
      text: 'Download on the App Store',
      onPressed: () => _openStore(AppConstants.iosUrl),
    );
    final androidButton = _buildStoreButton(
      button: Buttons.googleDark,
      text: 'Get it on Google Play',
      onPressed: () => _openStore(AppConstants.androidUrl),
    );

    if (isIOS) return [iosButton];
    if (isAndroid) return [androidButton];
    return [iosButton, const SizedBox(height: 10), androidButton];
  }

  Widget _buildStoreButton({
    required Buttons button,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: IgnorePointer(
        ignoring: _isOpeningStore,
        child: Opacity(
          opacity: _isOpeningStore ? 0.5 : 1.0,
          child: SignInButton(button, text: text, onPressed: onPressed),
        ),
      ),
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.headingText(context)),
              Text(
                description,
                style: AppStyles.smallSecondaryText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openStore(String storeUrl) async {
    setState(() => _isOpeningStore = true);

    final opened = await launchUrl(
      Uri.parse(storeUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the app store link.')),
      );
    }

    if (mounted) {
      setState(() => _isOpeningStore = false);
    }
  }

  Future<void> _continueOnWeb() async {
    await PrefService().setBool('mobile_web_continue', true);
    if (!mounted) return;

    final route = widget.nextRoute.isEmpty
        ? AppRoute.landingScreen
        : widget.nextRoute;
    context.go(route);
  }
}
